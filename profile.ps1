# Clear the console screen
[System.Console]::Clear()

# Remove conflicting aliases and set custom ones
Remove-Item -Path Alias:ls -ErrorAction Ignore
Remove-Item -Path Alias:cd -ErrorAction Ignore

Set-Alias -Name vi -Value "$env:programfiles\Neovim\bin\nvim.exe"
Set-Alias -Name touch -Value New-Item
Set-Alias -Name cd -Value z
Set-Alias -Name cdi -Value zi

if (Get-Command git -ErrorAction SilentlyContinue) {

    function ga     { git add .; git status }
    function gs     { git status @args }
    function gst    { git stash @args }
    function gstp   { git stash pop @args }
    function grmc   { git rm --cached @args }
    function grao   { git remote add origin @args }
    function gi     { git init @args }
    function gsw    { git switch @args }
    function gswc   { git switch -c @args }
    function gb     { git branch @args }
    function gbd    { git branch -d @args }
    function gbD    { git branch -D @args }
    function gbrd   { git push origin --delete @args }
    function gco    { git commit @args }
    function gca    { git commit --amend @args }
    function gcqundo { git reset --soft HEAD~1 @args }
    function gpl    { git pull @args }
    function gpush  { git push @args }
    function gpsf   { git push --force-with-lease @args }
    function glg    { git log --oneline --graph --decorate --all @args }
    function glog   { git log --oneline --decorate @args }
    function ghist  { git log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short @args }
    function gdf    { git diff @args }
    function gdc    { git diff --cached @args }
    function grs    { git restore . @args }
    function grss   { git restore --staged . @args }
    function grb    { git rebase @args }
    function grbi   { git rebase -i @args }
    function gcl    { git clone @args }
    function gfa    { git fetch --all --prune @args }
    function glast  { git log -1 HEAD @args }
    function gtags  { git tag -l @args }
    function gtagd  { git tag -d @args }
}

if (Get-Command poetry -ErrorAction SilentlyContinue) {

    function pi      { poetry install @args }
    function pu      { poetry update @args }
    function plock   { poetry lock @args }
    function pa      { poetry add @args }
    function pad     { poetry add --dev @args }
    function prm     { poetry remove @args }
    function prun    { poetry run @args }
    function prp     { poetry run python @args }
    function prt     { poetry run task @args }
    function ptest   { poetry run pytest @args }
    function pblack  { poetry run black . @args }
    function pisort  { poetry run isort . @args }
    function pmypy   { poetry run mypy . @args }
    function pvenv   { poetry env use python @args }
    function pvi     { poetry env info @args }
    function pshow   { poetry show @args }
    function ptree   { poetry show --tree @args }
    function poutdated { poetry show --outdated @args }
    function pch     { poetry check @args }
    function pbuild  { poetry build @args }
}

# Change directory using fzf to select a folder
function cdf {
    try {
        $selectedPath = Get-ChildItem -Directory -Recurse -ErrorAction SilentlyContinue -Force |
        ForEach-Object { $_.FullName } |
        fzf --preview 'echo {}'

        if ($selectedPath) {
            Set-Location -Path $selectedPath
        } else {
            Write-Host "No selection made."
        }
    } catch {
        Write-Host "An error occurred: $_"
    }
}

# Search text in a pipeline or input for a pattern
function grep {
    param (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)] [string[]] $Input,
        [Parameter(Position = 0, Mandatory = $true)] [string] $Pattern
    )
    process {
        $Input | Out-String -Stream | Select-String -Pattern $Pattern
    }
}

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

# Shutdown the system
function poweroff { shutdown /s /t 0 }

# Reboot the system
function reboot { shutdown /r /t 0 }

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

# Update all installed packages using Winget
function update {
    param ([Alias("f")] [switch] $Force)
    $wingetArgs = @("--all", "--silent", "--accept-package-agreements", "--accept-source-agreements")
    if ($Force) { $wingetArgs += "--force" }
    winget upgrade @wingetArgs
}

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
            $sourceInfo = if ($command.PSCommandPath -and $command.PSCommandPath -ne "") { "(Source: $($command.Source))" } else { "" }
            Write-Host "- $($command.Name) $sourceInfo"
        }
    } else {
        Write-Host "No matching command found for '$Name'."
    }
}

# Use eza as aliases for ls with different options
function la { eza -a $args }
function ll { eza -a -l $args }
function lt { eza -a -T $args }
function ls { eza $args }
# Open Notepad or files in Notepad
function n { notepad $args }

oh-my-posh init pwsh --config "$([Environment]::GetFolderPath('MyDocuments'))\TerminalThemes\oh-my-posh-theme.json" | Invoke-Expression

Invoke-Expression (& { (zoxide init powershell | Out-String) })