$profilePath = $PROFILE.CurrentUserCurrentHost
$requiredPolicy = "RemoteSigned"
$repoUrl = "https://github.com/DreamTimeZ/terminal-themes.git"
$repoName = "TerminalThemes"
$profileSourcePath = ".\profile.ps1"
$packages = @("junegunn.fzf", "Neovim.Neovim", "ajeetdsouza.zoxide", "JanDeDobbeleer.OhMyPosh", "eza-community.eza")
$documentsPath = [Environment]::GetFolderPath('MyDocuments')
$repoPath = Join-Path -Path $documentsPath -ChildPath $repoName

# Tests if the current execution policy is restrictive and requires adjustment to meet the required policy
function Test-ShouldAdjustExecutionPolicy {
    param (
        [Parameter(Mandatory = $true)][string]$currentPolicy,
        [Parameter(Mandatory = $true)][string]$requiredPolicy
    )
    # Policies that disallow script execution
    $restrictivePolicies = @('Restricted', 'AllSigned')
    # Return true only if the current policy is restrictive and does not meet the required policy
    return $restrictivePolicies -contains $currentPolicy -or $currentPolicy -ne $requiredPolicy
}

# Adjusts the execution policy to the required level if needed
function Set-ExecutionPolicyIfNeeded {
    try {
        $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
        if (Test-ShouldAdjustExecutionPolicy -currentPolicy $currentPolicy -requiredPolicy $requiredPolicy) {
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy $requiredPolicy -Force -ErrorAction Stop
            Write-Output "Execution policy set to $requiredPolicy successfully."
        }
    } catch {
        Write-Error "Failed to set execution policy. Error: $_"
        exit 1
    }
}

# Installs a package via winget if it is not already installed
function Install-PackageIfNeeded {
    param (
        [Parameter(Mandatory = $true)][string]$packageId,
        [bool]$isInteractive = $false
    )

    Write-Output "Checking if $packageId is installed..."
    if (-not (winget list --id $packageId -e | Select-String -Quiet $packageId)) {
        $installArgs = @(
            "--id", $packageId, "-e", "-s", "winget",
            "--accept-package-agreements", "--accept-source-agreements"
        )
        if ($isInteractive) { $installArgs += "--interactive" }

        try {
            winget install @installArgs
            if ($LastExitCode -ne 0) {
                throw "Failed to install $packageId"
            }
        } catch {
            Write-Output "Error installing $packageId`: ${_}"
        }
    }
}

# Clones a Git repository to the specified destination if it does not already exist
function Copy-GitRepositoryIfNeeded {
    param (
        [Parameter(Mandatory = $true)][string]$repoUrl,
        [Parameter(Mandatory = $true)][string]$destinationPath
    )

    if (-not (Test-Path -Path $destinationPath)) {
        Write-Output "Cloning repository from $repoUrl..."
        try {
            git clone $repoUrl $destinationPath
            if ($LastExitCode -ne 0) {
                throw "Failed to clone repository from $repoUrl"
            }
        } catch {
            Write-Error "Error cloning repository: ${_}"
        }
    } else {
        Write-Output "Repository already exists at $destinationPath. Skipping clone."
    }
}

# Writes or updates the PowerShell profile file at the specified path
function Write-ProfileFile {
    param (
        [Parameter(Mandatory = $true)][string]$sourcePath,
        [Parameter(Mandatory = $true)][string]$profilePath
    )

    $profileDir = [System.IO.Path]::GetDirectoryName($profilePath)
    if (-not (Test-Path -Path $profileDir)) {
        try {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        } catch {
            Write-Error "Error creating directory for PowerShell profile: $_"
            return
        }
    }

    $profileExists = Test-Path -Path $profilePath

    if ($profileExists) {
        $response = Read-Host "The profile file already exists. Do you want to overwrite it? (y/n)"
        if ($response -notin @('y', 'Y')) {
            Write-Output "Skipping profile setup as per user request."
            return
        }
    }

    try {
        Copy-Item -Path $sourcePath -Destination $profilePath -Force
        if ($LastExitCode -ne 0) {
            throw "Failed to set up PowerShell profile"
        }

        if ($profileExists) {
            Write-Output "PowerShell profile updated successfully."
        } else {
            Write-Output "PowerShell profile created successfully."
        }
    } catch {
        Write-Error "Error setting up PowerShell profile: $_"
    }
}

try {
    Write-Host "Tip: To install it for PowerShell Core (pwsh) instead of Windows PowerShell, simply run the install.ps1 in the pwsh terminal; everything else is handled automatically."
    Set-ExecutionPolicyIfNeeded

    foreach ($pkg in $packages) {
        Install-PackageIfNeeded -packageId $pkg
    }

    Install-PackageIfNeeded -packageId "Git.Git" -isInteractive $true
    # Clone Terminal Themes repository if not already cloned
    Copy-GitRepositoryIfNeeded -repoUrl $repoUrl -destinationPath $repoPath
    Write-ProfileFile -sourcePath $profileSourcePath -profilePath $profilePath

    Write-Output "Installation completed successfully."
} catch {
    Write-Error "An unexpected error occurred during the installation process. Error: $_"
    exit 1
}
