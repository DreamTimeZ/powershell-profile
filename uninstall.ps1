$profilePath = $PROFILE.CurrentUserCurrentHost
$requiredPolicy = "RemoteSigned"
$repoName = "TerminalThemes"
$packages = @("junegunn.fzf", "Neovim.Neovim", "ajeetdsouza.zoxide", "JanDeDobbeleer.OhMyPosh", "eza-community.eza", "Git.Git")
$documentsPath = [Environment]::GetFolderPath('MyDocuments')
$repoPath = Join-Path -Path $documentsPath -ChildPath $repoName

# Checks if the current execution policy is restrictive and requires adjustment
function Test-ShouldAdjustExecutionPolicy {
    param (
        [Parameter(Mandatory=$true)][string]$currentPolicy,
        [Parameter(Mandatory=$true)][string]$requiredPolicy
    )
    # Policies that disallow script execution
    $restrictivePolicies = @('Restricted', 'AllSigned')
    # Return true only if the current policy is restrictive and does not meet the required policy
    return $restrictivePolicies -contains $currentPolicy -or $currentPolicy -ne $requiredPolicy
}

# Sets the execution policy to the required level if necessary
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

# Checks if a specific package is installed
function Test-PackageInstalled {
    param (
        [Parameter(Mandatory = $true)][string]$packageId
    )
    return (winget list --id $packageId -e | Select-String -Quiet $packageId)
}

# Uninstalls a package if it is installed
function Uninstall-PackageIfInstalled {
    param (
        [Parameter(Mandatory = $true)][string]$packageId
    )

    try {
        if (Test-PackageInstalled -packageId $packageId) {
            $response = Read-Host "$packageId is installed. Do you want to uninstall it? (y/n)"
            if ($response -notin @('y', 'Y')) {
                return
            }

            Write-Output "Attempting to uninstall $packageId..."
            winget uninstall --id $packageId -e --accept-source-agreements
            if ($LastExitCode -ne 0) {
                throw "Failed to uninstall $packageId"
            }
            Write-Output "$packageId uninstalled successfully."
        }
    } catch {
        Write-Error "Error uninstalling $packageId`: $_"
    }
}

# Removes the PowerShell profile file if it exists
function Remove-ProfileFile {
    param (
        [Parameter(Mandatory = $true)][string]$profilePath
    )

    if (Test-Path -Path $profilePath) {
        try {
            Write-Output "Removing PowerShell profile file at $profilePath..."
            Remove-Item -Path $profilePath -Force -ErrorAction Stop
            Write-Output "PowerShell profile file removed successfully."
        } catch {
            Write-Error "Error removing PowerShell profile file: $_"
        }
    } else {
        Write-Output "PowerShell profile file does not exist. Skipping..."
    }
}

# Removes the cloned Git repository if it exists
function Remove-GitRepository {
    param (
        [Parameter(Mandatory = $true)][string]$repoPath
    )

    if (Test-Path -Path $repoPath) {
        try {
            Write-Output "Removing Git repository at $repoPath..."
            Remove-Item -Path $repoPath -Recurse -Force -ErrorAction Stop
            Write-Output "Git repository removed successfully."
        } catch {
            Write-Error "Error removing Git repository: $_"
        }
    } else {
        Write-Output "Git repository does not exist. Skipping..."
    }
}

# Uninstalls specified packages if they are installed
function Invoke-Uninstallation {
    param (
        [Parameter(Mandatory = $true)][array]$packages
    )

    Write-Output "Checking installed status for the specified packages..."
    $installedPackages = $packages | Where-Object { Test-PackageInstalled -packageId $_ }

    if ($installedPackages.Count -eq 0) {
        Write-Output "No installed packages found for uninstallation. Skipping package uninstallation."
        return
    }

    Write-Output "The following packages are installed and available for uninstallation:"
    $installedPackages | ForEach-Object { Write-Output "- $_" }

    $response = Read-Host "Do you want to uninstall all these packages? (y/n)"
    if ($response -in @('y', 'Y')) {
        Write-Output "Uninstalling all listed packages..."
        foreach ($pkg in $installedPackages) {
            Uninstall-PackageIfInstalled -packageId $pkg
        }
    } else {
        foreach ($pkg in $installedPackages) {
            Uninstall-PackageIfInstalled -packageId $pkg
        }
    }
}

try {
    Set-ExecutionPolicyIfNeeded

    Invoke-Uninstallation -packages $packages

    $response = Read-Host "Do you want to remove the cloned Git repository? (y/n)"
    if ($response -in @('y', 'Y')) {
        Remove-GitRepository -repoPath $repoPath
    } else {
        Write-Output "Skipping Git repository removal as per user request."
    }

    $response = Read-Host "Do you want to remove the PowerShell profile file? (y/n)"
    if ($response -in @('y', 'Y')) {
        Remove-ProfileFile -profilePath $profilePath
    } else {
        Write-Output "Skipping PowerShell profile file removal as per user request."
    }

    Write-Output "Uninstallation process completed successfully."
} catch {
    Write-Error "An unexpected error occurred during the uninstallation process. Error: $_"
    exit 1
}
