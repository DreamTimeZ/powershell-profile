#==================================================================================================
# POWERSHELL PROFILE CONFIGURATION
#==================================================================================================
# Description: Custom PowerShell profile with aliases, functions, and tool integrations
#==================================================================================================

# Clear the console screen
[System.Console]::Clear()

$startTime = Get-Date

# Cache command existence checks for performance (single PATH search)
$availableCommands = (Get-Command eza, git, zoxide, docker, ollama -ErrorAction SilentlyContinue).Name -replace '\.exe$', ''
$Commands = @{
    Eza     = 'eza' -in $availableCommands
    Git     = 'git' -in $availableCommands
    Zoxide  = 'zoxide' -in $availableCommands
    Docker  = 'docker' -in $availableCommands
    Ollama  = 'ollama' -in $availableCommands
}

#==================================================================================================
# BASIC ALIASES
#==================================================================================================

# Remove conflicting aliases and set custom ones
Remove-Item -Path Alias:ls -ErrorAction Ignore

if ($nvim = Get-Command nvim -CommandType Application -ErrorAction SilentlyContinue) {
    Set-Alias -Name vi -Value $nvim.Source
}
Set-Alias -Name touch -Value New-Item
Set-Alias -Name pbcopy -Value Set-Clipboard
Set-Alias -Name pbpaste -Value Get-Clipboard

#--------------------------------------------------------------------------------------------------
# EZA (Modern ls replacement)
#--------------------------------------------------------------------------------------------------
if ($Commands.Eza) {
    function ls { eza --color=auto --group-directories-first @args }
    function l { eza -l --color=auto --group-directories-first @args }
    function ll { eza -l --color=auto --group-directories-first --icons=auto @args }
    function la { eza -lA --color=auto --group-directories-first --icons=auto @args }
    function ld { eza -lD --color=auto --icons=auto @args }
    function lh { eza -ld --color=auto --icons=auto .* 2>$null }
    function tree { eza --tree --level=2 --color=auto --icons=auto @args }
    function ltree { eza --tree --level=3 --color=auto --icons=auto @args }
}

#--------------------------------------------------------------------------------------------------
# GIT ALIASES
#--------------------------------------------------------------------------------------------------
if ($Commands.Git) {
    # Status & Staging
    function gs { git status @args }
    function ga { git add @args }
    function gapa { git add --patch @args }
    function gaa { git add -A; git status }
    function gsta { git stash push @args }
    function gstp { git stash pop }
    function grmc { git rm --cached @args }

    # Repository Management
    function gi { git init @args }
    function gcl { git clone @args }
    function grao { git remote add origin @args }

    # Branch Management
    function gb { git branch @args }
    function gsw { git switch @args }
    function gswc { git switch -c @args }
    function gbd { git branch -d @args }
    function gbD { git branch -D @args }
    function gbrd { git push origin --delete @args }

    # Commits
    function gc { git commit @args }
    function gcmsg { git commit -m @args }
    function gca { git commit --amend @args }
    function gundo { git reset --soft HEAD~1 }

    # Push/Pull
    function gpl { git pull @args }
    function gps { git push @args }
    function gpsf { git push --force-with-lease }

    # Logs & History
    function glog { git log @args }
    function glo { git log --oneline --decorate @args }
    function glg { git log --oneline --graph --decorate --all }
    function ghist { git log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short }
    function glast { git log -1 HEAD }
    function gsh { git show @args }

    # Diffs & Changes
    function gd { git diff @args }
    function gds { git diff --staged @args }
    function gdh { git diff HEAD @args }
    function gr { git restore @args }
    function grs { git restore --staged @args }

    # Advanced Operations
    function gm { git merge @args }
    function gcp { git cherry-pick @args }
    function grb { git rebase @args }
    function grbi { git rebase -i @args }
    function grbc { git rebase --continue }
    function grba { git rebase --abort }
    function gfa { git fetch --all --prune }

    # Tags
    function gtags { git tag -l }
    function gtagd { git tag -d @args }
}

#--------------------------------------------------------------------------------------------------
# NAVIGATION SHORTCUTS
#--------------------------------------------------------------------------------------------------
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function ..... { Set-Location ../../../.. }
function ...... { Set-Location ../../../../.. }
function ....... { Set-Location ../../../../../.. }
function ........ { Set-Location ../../../../../../.. }

#--------------------------------------------------------------------------------------------------
# ZOXIDE (Smart directory navigation)
#--------------------------------------------------------------------------------------------------
if ($Commands.Zoxide) {
    function cdi { zoxide query --interactive }
    function cdf {
        $dest = zoxide query --interactive
        if ($dest) { Set-Location $dest }
    }
}

#--------------------------------------------------------------------------------------------------
# DOCKER
#--------------------------------------------------------------------------------------------------
if ($Commands.Docker) {
    Set-Alias d docker
    function dps { docker ps @args }
    function dpsa { docker ps -a @args }
    function di { docker images @args }
    function dex { docker exec -it @args }
    function dlogs { docker logs -f @args }

    # Docker Compose
    function dc { docker compose @args }
    function dcup { docker compose up -d @args }
    function dcupb { docker compose up -d --build @args }
    function dcdown { docker compose down @args }
    function dcdownrm { docker compose down --remove-orphans @args }
    function dclogs { docker compose logs -f @args }

    # Cleanup
    function dprune { docker system prune @args }
    function dprune-all { docker system prune -a @args }
}

#--------------------------------------------------------------------------------------------------
# APPLICATION LAUNCHERS
#--------------------------------------------------------------------------------------------------
function n { notepad $args }
function obsidian { & "$env:userprofile\AppData\Local\Programs\Obsidian\Obsidian.exe" $args }
function firefox { & "$env:programfiles\Mozilla Firefox\firefox.exe" $args }
function dockerd { & "$env:programfiles\Docker\Docker\Docker Desktop.exe" $args}

#--------------------------------------------------------------------------------------------------
# OLLAMA (Local LLM management)
#--------------------------------------------------------------------------------------------------
if ($Commands.Ollama) {
    function ollama-up {
        if (-not (Get-Process ollama -ErrorAction SilentlyContinue)) {
            Start-Process -WindowStyle Hidden -FilePath ollama -ArgumentList 'serve'
        }
    }
}

#==================================================================================================
# UTILITY FUNCTIONS
#==================================================================================================

#--------------------------------------------------------------------------------------------------
# Profile & Environment Management
#--------------------------------------------------------------------------------------------------
function reload { . $PROFILE }
function reload-path {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}
function path { $env:Path -split ';' | Where-Object { $_ } }

#--------------------------------------------------------------------------------------------------
# Text Search & Processing
#--------------------------------------------------------------------------------------------------
# Search text in a pipeline or input for a pattern
function grep {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]] $InputObject,
        [Parameter(Position = 0, Mandatory = $true)]
        [string] $Pattern
    )
    process {
        if ($InputObject) {
            $InputObject | Select-String -Pattern $Pattern
        }
    }
}

#--------------------------------------------------------------------------------------------------
# Process Management
#--------------------------------------------------------------------------------------------------
# Kill a process by name
function pkill {
    param ([string] $ProcessName)
    if ($Process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) {
        Write-Host "$ProcessName is running. Stopping..."
        $Process | Stop-Process -Force
    } else {
        Write-Host "$ProcessName is not running."
    }
}

#--------------------------------------------------------------------------------------------------
# System Power Management
#--------------------------------------------------------------------------------------------------
# Shutdown the system
function poweroff { shutdown /s /t 0 }

# Reboot the system
function reboot { shutdown /r /t 0 }

#--------------------------------------------------------------------------------------------------
# Network Information
#--------------------------------------------------------------------------------------------------
# Retrieve public and local IPv4 addresses
function IPv4 {
    [CmdletBinding()]
    param (
        # Optional domain parameter to fetch IP address for a given domain
        [Alias("d")]
        [ValidateScript({
                if ($_ -match "^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$") { $true }
                else { throw "Invalid domain format" }
            })]
        [string]$Domain
    )

    if ($Domain) {
        # If a domain is specified, get the IPv4 address for the domain only
        try {
            $domainIP = [System.Net.Dns]::GetHostAddresses($Domain) |
            Where-Object AddressFamily -eq 'InterNetwork' |
            Select-Object -First 1
            if ($domainIP) {
                Write-Output "IPv4 Address for ${Domain}:"
                Write-Output "  - $($domainIP.IPAddressToString)"
            } else {
                Write-Output "`nNo IPv4 address found for ${Domain}."
            }
        } catch {
            Write-Output "`nError resolving IP for ${Domain}: ${_}"
        }
    } else {
        # If no domain is specified, get local and public IPv4 addresses

        # Local IPv4 addresses
        Write-Output "=== Local IPv4 Addresses ==="
        $localIPs = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.IPAddress -notmatch "^(169\.|127\.)" } |
        Sort-Object IPAddress |
        Select-Object -Property IPAddress, InterfaceAlias

        if ($localIPs) {
            # Display each local IP address in a list format
            $localIPs | ForEach-Object {
                Write-Output "  - $($_.IPAddress) on interface: $($_.InterfaceAlias)"
            }
        } else {
            Write-Output "  No local IPv4 addresses found."
        }

        # Public IPv4 address
        Write-Output "`n=== Public IPv4 Address ==="
        try {
            $publicIP = Invoke-RestMethod -Uri "https://ipinfo.io/ip" -ErrorAction Stop
            if ($publicIP) {
                Write-Output "  - $publicIP"
            } else {
                Write-Output "  Unable to retrieve public IP address."
            }
        } catch {
            Write-Output "  Unable to retrieve public IP address: ${_}"
        }
    }
}

# Retrieve public and local IPv6 addresses
function IPv6 {
    [CmdletBinding()]
    param (
        # Optional domain parameter to fetch IPv6 address for a given domain
        [Alias("d")]
        [ValidateScript({
                if ($_ -match "^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$") { $true }
                else { throw "Invalid domain format" }
            })]
        [string]$Domain
    )

    # Function to determine the type of an IPv6 address
    function Get-IPv6Type {
        param ($IPAddress)
        switch -Regex ($IPAddress) {
            "^fe80" { return "Link-Local" }
            "^fc|^fd" { return "Unique Local" }
            "^2" { return "Global" }
            default { return "Unknown" }
        }
    }

    if ($Domain) {
        # Use Resolve-DnsName to retrieve IPv6 (AAAA) records for the domain
        try {
            $domainIPs = (Resolve-DnsName -Name $Domain -Type AAAA -ErrorAction Stop).IPAddress

            if ($domainIPs) {
                Write-Output "IPv6 Address(es) for ${Domain}:"
                $domainIPs | ForEach-Object {
                    Write-Output "  - $_"
                }
            } else {
                Write-Output "`nNo IPv6 address found for ${Domain}. This domain may not have an IPv6 address."
            }
        } catch {
            Write-Output "`nError resolving IP for ${Domain}: ${_}. Check connectivity or domain validity."
        }
    } else {
        # If no domain is specified, get local and public IPv6 addresses

        # Local IPv6 addresses
        Write-Output "=== Local IPv6 Addresses ==="
        $localIPs = Get-NetIPAddress -AddressFamily IPv6 |
        Where-Object { $_.IPAddress -notmatch "^(::1)" } |  # Exclude loopback (::1)
        Sort-Object IPAddress |
        Select-Object -Property IPAddress, InterfaceAlias

        if ($localIPs) {
            # Display each local IPv6 address with its type in a list format
            $localIPs | ForEach-Object {
                $ipType = Get-IPv6Type -IPAddress $_.IPAddress
                Write-Output "  - $($_.IPAddress) on interface: $($_.InterfaceAlias) ($ipType)"
            }
        } else {
            Write-Output "  No local IPv6 addresses found."
        }

        # Public IPv6 address
        Write-Output "`n=== Public IPv6 Address ==="
        try {
            $publicIPResponse = Invoke-RestMethod -Uri "https://api64.ipify.org?format=json" -ErrorAction Stop
            if ($publicIPResponse) {
                $publicIP = $publicIPResponse.ip
                # Check if the returned IP is IPv6
                if ($publicIP -match ":") {
                    Write-Output "  - $publicIP"
                } else {
                    Write-Output "  - $publicIP (Fallback to IPv4)"
                }
            } else {
                Write-Output "  Unable to retrieve public IP address."
            }
        } catch {
            Write-Output "  Unable to retrieve public IP address: ${_}"
        }
    }
}

#--------------------------------------------------------------------------------------------------
# Package Management
#--------------------------------------------------------------------------------------------------
# Update all installed packages using Winget
function update {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Alias('f')][switch] $Force,
        [Alias('s')][switch] $Silent
    )

    $wingetArgs = @(
        'upgrade'
        '--all'
        '--accept-package-agreements'
        '--accept-source-agreements'
    )

    if (-not $Silent) {
        $wingetArgs += '--interactive'
    } else {
        $wingetArgs += @('--silent')
    }

    if ($Force) { $wingetArgs += '--force' }

    if ($PSCmdlet.ShouldProcess('All packages', 'Upgrade')) {
        winget @wingetArgs
    }
}

#--------------------------------------------------------------------------------------------------
# System Information
#--------------------------------------------------------------------------------------------------
# Display system uptime
function uptime {
    $lastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $lastBootTime

    $lastBootTimeString = $lastBootTime.ToString("yyyy-MM-dd HH:mm:ss")

    $uptimeDays = $uptime.Days
    $uptimeHours = $uptime.Hours
    $uptimeMinutes = $uptime.Minutes

    $uptimeString = ""
    
    if ($uptimeDays -gt 0) {
        $uptimeString += "$uptimeDays day"
        if ($uptimeDays -ne 1) { $uptimeString += "s" }
        $uptimeString += ", "
    }

    $uptimeString += "$uptimeHours hour"
    if ($uptimeHours -ne 1) { $uptimeString += "s" }
    $uptimeString += ", "

    $uptimeString += "$uptimeMinutes minute"
    if ($uptimeMinutes -ne 1) { $uptimeString += "s" }

    return "System last booted: $lastBootTimeString`nUptime: $uptimeString"
}

#--------------------------------------------------------------------------------------------------
# PowerShell Command History & Discovery
#--------------------------------------------------------------------------------------------------
# Show system wide history for powershell commands
function hist { Get-Content (Get-PSReadlineOption).HistorySavePath }

# Search for commands matching a pattern
function gcmd {
    [CmdletBinding()] # For Parameter validation and ErrorAction
    param (
        [Parameter(Mandatory = $true)] [string] $Name
    )

    $matchingCommands = Get-Command -Name "*$Name*" -ErrorAction SilentlyContinue

    if ($matchingCommands.Count -gt 0) {
        # Shorter names are considered better matches
        $matchingCommands = $matchingCommands | Sort-Object { $_.Name.Length }

        $topMatches = $matchingCommands | Select-Object -First 5

        Write-Host "Top matching commands for '$Name':"
        foreach ($command in $topMatches) {
            # Check if the Source property exists and is not empty
            $sourceInfo = if ($command.Source) { "(Source: $($command.Source))" } else { "" }
            Write-Host "- $($command.Name) $sourceInfo"
        }
    } else {
        Write-Host "No matching command found for '$Name'."
    }
}

#==================================================================================================
# PROMPT & SHELL INITIALIZATION
#==================================================================================================

$startTimeTheme = Get-Date

# Oh My Posh - Prompt theme engine
# oh-my-posh init pwsh --config "$([Environment]::GetFolderPath('MyDocuments'))\TerminalThemes\oh-my-posh-theme.json" | Invoke-Expression

# Starship - Alternative prompt theme (cached for performance)
if (Get-Command starship -CommandType Application -ErrorAction SilentlyContinue) {
    $ENV:STARSHIP_CONFIG = "$([Environment]::GetFolderPath('MyDocuments'))\TerminalThemes\starship-theme.toml"
    $starshipCache = "$env:TEMP\starship-init-$($PSVersionTable.PSVersion.Major).ps1"
    if (-not (Test-Path $starshipCache)) {
        & starship init powershell | Out-File $starshipCache -Encoding utf8
    }
    . $starshipCache
    function Invoke-Starship-TransientFunction {
        & starship module character
    }
    Enable-TransientPrompt
}

$endTime = Get-Date
$totalMs = ($endTime - $startTime).TotalMilliseconds
$themeMs = ($endTime - $startTimeTheme).TotalMilliseconds

$totalDisplay = if ($totalMs -ge 1000) { "{0:F2} s" -f ($totalMs / 1000) } else { "{0:F0} ms" -f $totalMs }
$themeDisplay = if ($themeMs -ge 1000) { "{0:F2} s" -f ($themeMs / 1000) } else { "{0:F0} ms" -f $themeMs }

Write-Host "Terminal startup time: $totalDisplay (Theme: $themeDisplay)"

# Zoxide - Smart directory jumper initialization (cached for performance)
if ($Commands.Zoxide) {
    $zoxideCache = "$env:TEMP\zoxide-init-$($PSVersionTable.PSVersion.Major).ps1"
    if (-not (Test-Path $zoxideCache)) {
        & zoxide init powershell | Out-File $zoxideCache -Encoding utf8
    }
    . $zoxideCache
}
