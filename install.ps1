<#
.SYNOPSIS
    Install PowerShell profile with dependencies and themes via symbolic links.

.PARAMETER Profile
    Profile scope:
    - current (default): Current user, current host
    - all-hosts: Current user, all hosts
    - all-users: All users, current host (requires admin)
    - global: All users, all hosts (requires admin)

.PARAMETER Shell
    Target shell:
    - current (default): Detects current shell (pwsh uses Documents\PowerShell, Windows PowerShell uses Documents\WindowsPowerShell)
    - windows: Windows PowerShell 5.1 (Documents\WindowsPowerShell)
    - pwsh: PowerShell 7+ (Documents\PowerShell)
    - both: Install to both shells

.EXAMPLE
    .\install.ps1
    .\install.ps1 -Profile all-hosts -Shell both
    .\install.ps1 -Shell pwsh
#>

param(
    [ValidateSet('current', 'all-hosts', 'all-users', 'global')]
    [string]$Profile = 'current',

    [ValidateSet('current', 'windows', 'pwsh', 'both')]
    [string]$Shell = 'current'
)

# Detect current shell
$currentShell = if ($PSVersionTable.PSVersion.Major -ge 6) { 'pwsh' } else { 'windows' }

# Map friendly names to PowerShell profile properties
$profileMap = @{
    'current'    = 'CurrentUserCurrentHost'  # Default: Current user, current PowerShell host
    'all-hosts'  = 'CurrentUserAllHosts'     # Current user, all PowerShell hosts
    'all-users'  = 'AllUsersCurrentHost'     # All users, current PowerShell host
    'global'     = 'AllUsersAllHosts'        # All users, all PowerShell hosts
}

# Determine which shells to target
$targetShells = @()
if ($Shell -eq 'current') {
    $targetShells += $currentShell
} elseif ($Shell -eq 'both') {
    $targetShells += @('windows', 'pwsh')
} else {
    $targetShells += $Shell
}

$profileScope = $profileMap[$Profile]

$requiredPolicy = "RemoteSigned"
$repoUrl = "https://github.com/DreamTimeZ/terminal-themes.git"
$repoName = "TerminalThemes"
$profileSourcePath = ".\profile.ps1"
$packages = @("junegunn.fzf", "Neovim.Neovim", "ajeetdsouza.zoxide", "JanDeDobbeleer.OhMyPosh", "Starship.Starship", "eza-community.eza")
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
    # Try to import the Security module if Get-ExecutionPolicy isn't available
    if (-not (Get-Command Get-ExecutionPolicy -ErrorAction SilentlyContinue)) {
        try {
            Import-Module Microsoft.PowerShell.Security -ErrorAction Stop
        } catch {
            # If the Security module can't be loaded but we're running this script,
            # it means we already have sufficient permissions (likely via -ExecutionPolicy Bypass)
            return
        }
    }

    try {
        # Check if we're already running with Bypass or Unrestricted (e.g., from batch file)
        $processPolicy = Get-ExecutionPolicy -Scope Process -ErrorAction Stop
        if ($processPolicy -in @('Bypass', 'Unrestricted')) {
            return
        }

        $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction Stop
        if (Test-ShouldAdjustExecutionPolicy -currentPolicy $currentPolicy -requiredPolicy $requiredPolicy) {
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy $requiredPolicy -Force -ErrorAction Stop
            Write-Output "Execution policy set to $requiredPolicy successfully."
        }
    } catch {
        # If we can't check or set execution policy but we're running this script,
        # it means we already have sufficient permissions (likely via -ExecutionPolicy Bypass)
        return
    }
}

# Installs a package via winget if it is not already installed
function Install-PackageIfNeeded {
    param (
        [Parameter(Mandatory = $true)][string]$packageId,
        [bool]$isInteractive = $false
    )

    if (-not (winget list --id $packageId -e 2>$null | Select-String -Quiet $packageId)) {
        Write-Output "Installing $packageId..."
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
        Write-Output "Cloning terminal themes..."
        try {
            git clone $repoUrl $destinationPath
            if ($LastExitCode -ne 0) {
                throw "Failed to clone repository from $repoUrl"
            }
        } catch {
            Write-Error "Error cloning repository: ${_}"
        }
    }
}

# Get profile path for specific shell and scope
function Get-ProfilePath {
    param (
        [Parameter(Mandatory = $true)][string]$shell,
        [Parameter(Mandatory = $true)][string]$scope
    )

    $documentsPath = [Environment]::GetFolderPath('MyDocuments')

    # Determine base directory based on shell
    $shellDir = if ($shell -eq 'pwsh') { 'PowerShell' } else { 'WindowsPowerShell' }

    # Determine profile filename based on scope
    $profileName = switch ($scope) {
        'CurrentUserCurrentHost' { 'Microsoft.PowerShell_profile.ps1' }
        'CurrentUserAllHosts'    { 'profile.ps1' }
        'AllUsersCurrentHost'    {
            $programFiles = [Environment]::GetFolderPath('ProgramFiles')
            return Join-Path -Path $programFiles -ChildPath "$shellDir\Microsoft.PowerShell_profile.ps1"
        }
        'AllUsersAllHosts'       {
            $programFiles = [Environment]::GetFolderPath('ProgramFiles')
            return Join-Path -Path $programFiles -ChildPath "$shellDir\profile.ps1"
        }
    }

    # For CurrentUser scopes
    if ($scope -like 'CurrentUser*') {
        return Join-Path -Path $documentsPath -ChildPath "$shellDir\$profileName"
    }

    return $profileName
}

# Creates a symbolic link for the PowerShell profile file at the specified path
function Write-ProfileFile {
    param (
        [Parameter(Mandatory = $true)][string]$sourcePath,
        [Parameter(Mandatory = $true)][string]$profilePath,
        [Parameter(Mandatory = $true)][string]$shellName
    )

    $profileDir = [System.IO.Path]::GetDirectoryName($profilePath)
    $absoluteSourcePath = Resolve-Path -Path $sourcePath

    # Check if running as administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Output "Creating symbolic link for $shellName requires administrator privileges. Requesting elevation..."
        $command = "New-Item -ItemType Directory -Path '$profileDir' -Force; New-Item -ItemType SymbolicLink -Path '$profilePath' -Target '$absoluteSourcePath' -Force"
        Start-Process powershell -Verb RunAs -WindowStyle Hidden -ArgumentList "-Command", $command -Wait

        # Verify the symlink was created
        if (Test-Path -Path $profilePath) {
            Write-Output "[$shellName] Profile symbolic link created successfully at: $profilePath"
        } else {
            Write-Error "[$shellName] Failed to create symbolic link. Please check permissions."
        }
        return
    }

    # If already admin, create the symlink directly
    if (-not (Test-Path -Path $profileDir)) {
        try {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        } catch {
            Write-Error "[$shellName] Error creating directory for PowerShell profile: $_"
            return
        }
    }

    $profileExists = Test-Path -Path $profilePath

    if ($profileExists) {
        $response = Read-Host "[$shellName] Profile already exists at $profilePath. Overwrite? (y/n)"
        if ($response -notin @('y', 'Y')) {
            Write-Output "[$shellName] Skipping profile setup as per user request."
            return
        }
        # Remove existing file/symlink before creating new one
        Remove-Item -Path $profilePath -Force
    }

    try {
        New-Item -ItemType SymbolicLink -Path $profilePath -Target $absoluteSourcePath -Force | Out-Null
        Write-Output "[$shellName] Profile symbolic link created successfully at: $profilePath"
    } catch {
        Write-Error "[$shellName] Error creating symbolic link for PowerShell profile: $_"
    }
}

try {
    # Show detected shell information
    $shellInfo = if ($Shell -eq 'current') {
        $detectedName = if ($currentShell -eq 'pwsh') { 'PowerShell 7+' } else { 'Windows PowerShell 5.1' }
        $detectedDir = if ($currentShell -eq 'pwsh') { 'PowerShell' } else { 'WindowsPowerShell' }
        "Detected: $detectedName (using Documents\$detectedDir)"
    } else {
        ""
    }

    Write-Output "Installing PowerShell profile ($profileScope) for $($targetShells -join ', ')..."
    if ($shellInfo) { Write-Output $shellInfo }
    Write-Output ""

    Set-ExecutionPolicyIfNeeded

    foreach ($pkg in $packages) {
        Install-PackageIfNeeded -packageId $pkg
    }

    Install-PackageIfNeeded -packageId "Git.Git" -isInteractive $true
    # Clone Terminal Themes repository if not already cloned
    Copy-GitRepositoryIfNeeded -repoUrl $repoUrl -destinationPath $repoPath

    # Create symlinks for each target shell
    Write-Output "`nCreating profile links..."
    foreach ($targetShell in $targetShells) {
        $targetProfilePath = Get-ProfilePath -shell $targetShell -scope $profileScope
        $shellDisplayName = if ($targetShell -eq 'pwsh') { 'PowerShell 7+' } else { 'Windows PowerShell' }

        Write-ProfileFile -sourcePath $profileSourcePath -profilePath $targetProfilePath -shellName $shellDisplayName
    }

    Write-Output "`nInstallation complete."
} catch {
    Write-Error "An unexpected error occurred during the installation process. Error: $_"
    exit 1
}
