<#
.SYNOPSIS
    Uninstall PowerShell profile, dependencies, and themes.

.PARAMETER Profile
    Profile scope to remove:
    - current (default): Current user, current host
    - all-hosts: Current user, all hosts
    - all-users: All users, current host
    - global: All users, all hosts

.PARAMETER Shell
    Target shell: current (default) | windows | pwsh | both

.EXAMPLE
    .\uninstall.ps1
    .\uninstall.ps1 -Profile all-hosts -Shell both
    .\uninstall.ps1 -Shell pwsh
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
    'current'    = 'CurrentUserCurrentHost'
    'all-hosts'  = 'CurrentUserAllHosts'
    'all-users'  = 'AllUsersCurrentHost'
    'global'     = 'AllUsersAllHosts'
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
$repoName = "TerminalThemes"
$packages = @("junegunn.fzf", "Neovim.Neovim", "ajeetdsouza.zoxide", "JanDeDobbeleer.OhMyPosh", "Starship.Starship", "eza-community.eza", "Git.Git")
$documentsPath = [Environment]::GetFolderPath('MyDocuments')
$repoPath = Join-Path -Path $documentsPath -ChildPath $repoName

# Checks if the current execution policy is restrictive and requires adjustment
function Test-ShouldAdjustExecutionPolicy {
    param (
        [Parameter(Mandatory=$true)][string]$currentPolicy
    )
    $restrictivePolicies = @('Restricted', 'AllSigned')
    return $restrictivePolicies -contains $currentPolicy
}

# Sets the execution policy to the required level if necessary
function Set-ExecutionPolicyIfNeeded {
    try {
        $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
        if (Test-ShouldAdjustExecutionPolicy -currentPolicy $currentPolicy) {
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

# Get profile path for specific shell and scope
function Get-ProfilePath {
    param (
        [Parameter(Mandatory = $true)][string]$shell,
        [Parameter(Mandatory = $true)][string]$scope
    )

    $documentsPath = [Environment]::GetFolderPath('MyDocuments')
    $shellDir = if ($shell -eq 'pwsh') { 'PowerShell' } else { 'WindowsPowerShell' }

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

    if ($scope -like 'CurrentUser*') {
        return Join-Path -Path $documentsPath -ChildPath "$shellDir\$profileName"
    }

    return $profileName
}

# Removes the PowerShell profile file or symbolic link if it exists
function Remove-ProfileFile {
    param (
        [Parameter(Mandatory = $true)][string]$profilePath,
        [Parameter(Mandatory = $true)][string]$shellName
    )

    if (Test-Path -Path $profilePath) {
        try {
            $item = Get-Item -Path $profilePath
            $isSymlink = $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint

            if ($isSymlink) {
                Write-Output "[$shellName] Removing profile symbolic link..."
                Remove-Item -Path $profilePath -Force -ErrorAction Stop
                Write-Output "[$shellName] Profile symbolic link removed successfully."
            } else {
                Write-Output "[$shellName] Removing profile file..."
                Remove-Item -Path $profilePath -Force -ErrorAction Stop
                Write-Output "[$shellName] Profile file removed successfully."
            }
        } catch {
            Write-Error "[$shellName] Error removing profile: $_"
        }
    } else {
        Write-Output "[$shellName] Profile does not exist at $profilePath. Skipping..."
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
            Write-Output "Uninstalling $pkg..."
            winget uninstall --id $pkg -e --accept-source-agreements
        }
    } else {
        foreach ($pkg in $installedPackages) {
            Uninstall-PackageIfInstalled -packageId $pkg
        }
    }
}

try {
    Write-Host "=== PowerShell Profile Uninstallation ===`n"
    Write-Host "Running from:    $currentShell"
    Write-Host "Target shell(s): $($targetShells -join ', ')"
    Write-Host "Profile scope:   $profileScope ($Profile)`n"

    Set-ExecutionPolicyIfNeeded

    Invoke-Uninstallation -packages $packages

    $response = Read-Host "Do you want to remove the cloned Git repository? (y/n)"
    if ($response -in @('y', 'Y')) {
        Remove-GitRepository -repoPath $repoPath
    } else {
        Write-Output "Skipping Git repository removal as per user request."
    }

    $response = Read-Host "Do you want to remove the PowerShell profile(s)? (y/n)"
    if ($response -in @('y', 'Y')) {
        Write-Host "`n=== Removing Profile Symbolic Links ===`n"
        foreach ($targetShell in $targetShells) {
            $targetProfilePath = Get-ProfilePath -shell $targetShell -scope $profileScope
            $shellDisplayName = if ($targetShell -eq 'pwsh') { 'PowerShell 7+' } else { 'Windows PowerShell' }

            Write-Host "Processing $shellDisplayName..."
            Remove-ProfileFile -profilePath $targetProfilePath -shellName $shellDisplayName
        }
    } else {
        Write-Output "Skipping PowerShell profile removal as per user request."
    }

    Write-Output "`nUninstallation process completed successfully."
} catch {
    Write-Error "An unexpected error occurred during the uninstallation process. Error: $_"
    exit 1
}
