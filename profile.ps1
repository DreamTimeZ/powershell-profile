#==================================================================================================
# POWERSHELL PROFILE CONFIGURATION
#==================================================================================================
# Description: Custom PowerShell profile with aliases, functions, and tool integrations
#==================================================================================================

# Cache command existence checks for performance (single PATH search)
# Strip the launcher extension so npm/.cmd shims (e.g. codex.cmd) match their bare name too.
$availableCommands = (Get-Command eza, git, zoxide, docker, uv, nvim, starship, claude, codex, kubectl, lazygit, gitleaks -CommandType Application -ErrorAction Ignore).Name -replace '\.(exe|cmd|bat|ps1)$', ''
$Commands = @{
    Eza      = 'eza' -in $availableCommands
    Git      = 'git' -in $availableCommands
    Zoxide   = 'zoxide' -in $availableCommands
    Docker   = 'docker' -in $availableCommands
    Uv       = 'uv' -in $availableCommands
    Nvim     = 'nvim' -in $availableCommands
    Starship = 'starship' -in $availableCommands
    Claude   = 'claude' -in $availableCommands
    Codex    = 'codex' -in $availableCommands
    Kubectl  = 'kubectl' -in $availableCommands
    Lazygit  = 'lazygit' -in $availableCommands
    Gitleaks = 'gitleaks' -in $availableCommands
}

#==================================================================================================
# BASIC ALIASES
#==================================================================================================

# Remove conflicting aliases and set custom ones
Remove-Item -Path Alias:ls -ErrorAction Ignore

if ($Commands.Nvim) {
    Set-Alias -Name vi -Value nvim
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
    function gin { git init @args }
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
    function gct { git commit @args }
    function gcmsg { git commit -m @args }
    function gca { git commit --amend @args }
    function gundo { git reset --soft HEAD~1 }

    # Push/Pull
    function gpl { git pull @args }
    function gpsh { git push @args }
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
    function gmr { git merge @args }
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
# Lazy-checked: ollama not in startup batch to avoid PATH scan penalty
function ollama-up {
    if (-not (Get-Command ollama -CommandType Application -ErrorAction Ignore)) {
        Write-Host "ollama is not installed."
        return
    }
    if (-not (Get-Process ollama -ErrorAction SilentlyContinue)) {
        Start-Process -WindowStyle Hidden -FilePath ollama -ArgumentList 'serve'
    }
}

#--------------------------------------------------------------------------------------------------
# UV (Python package manager)
#--------------------------------------------------------------------------------------------------
if ($Commands.Uv) {
    # Package Management
    function uvr { uv run @args }
    function uvs { uv sync @args }
    function uva { uv add @args }
    function uvrm { uv remove @args }

    # Dependency Groups
    function uvd { uv add --group dev @args }
    function uvt { uv add --group test @args }

    # Testing
    function pyt { uv run pytest @args }
}

#--------------------------------------------------------------------------------------------------
# AI CODING AGENTS (Claude Code & Codex)
#--------------------------------------------------------------------------------------------------
# Model + effort scheme. Naming: the bare alias is that model's daily default; suffixes
# -h/-x/-m = effort high/xhigh/max, -u = ultracode, -z = zero-context.
# Every alias pins --model explicitly so the settings.json default model never leaks in.
if ($Commands.Claude) {
    Set-Alias -Name c -Value claude

    # Opus (daily driver)
    function cy  { claude --model opus --effort xhigh @args }   # bare = Opus daily default
    function cyh { claude --model opus --effort high @args }
    function cyx { claude --model opus --effort xhigh @args }
    function cym { claude --model opus --effort max @args }     # --effort is the only way to start at max
    function cyu { claude --model opus --settings '{"ultracode":true}' @args }   # no --effort: max disables ultracode

    # Sonnet (fast, quality-balanced)
    function cf  { claude --model sonnet --effort high @args }  # bare = Sonnet daily default
    function cfh { claude --model sonnet --effort high @args }
    function cfx { claude --model sonnet --effort xhigh @args }
    function cfm { claude --model sonnet --effort max @args }
    function cfu { claude --model sonnet --settings '{"ultracode":true}' @args }

    # Haiku (cheap, trivial tasks)
    function ch  { claude --model haiku --effort medium @args } # bare = Haiku daily default
    function chh { claude --model haiku --effort high @args }
    function chx { claude --model haiku --effort xhigh @args }
    function chm { claude --model haiku --effort max @args }
    function chu { claude --model haiku --settings '{"ultracode":true}' @args }

    # Fable 5
    function cb  { claude --model fable @args }                 # bare = Fable default (inherits settings.json effort)
    function cbh { claude --model fable --effort high @args }
    function cbx { claude --model fable --effort xhigh @args }
    function cbm { claude --model fable --effort max @args }
    function cbu { claude --model fable --settings '{"ultracode":true}' @args }

    # Name-by-model helpers (complement the letter scheme)
    function claudeh { claude --model haiku @args }
    function claudes { claude --model sonnet @args }
    function claudeo { claude --model opus @args }
    function claudep { claude -p @args }
    function cbare   { claude --bare @args }

    # Tool-restricted variants
    function claudew { claude --allowedTools "WebFetch,WebSearch" @args }
    function claudef { claude --allowedTools "Glob,Grep,Read" @args }
    function claudet { claude --allowedTools "Edit,Write,Bash,WebFetch,WebSearch" @args }

    # Zero-context (-z): --safe-mode disables all config. Auto-memory is disabled for the call only
    # (set-then-restore around the invocation, since PowerShell has no inline env-var prefix).
    function Invoke-ClaudeSafe {
        $previousDisableAutoMemory = $env:CLAUDE_CODE_DISABLE_AUTO_MEMORY
        $env:CLAUDE_CODE_DISABLE_AUTO_MEMORY = '1'
        try {
            claude @args
        } finally {
            if ($null -eq $previousDisableAutoMemory) {
                Remove-Item -Path Env:CLAUDE_CODE_DISABLE_AUTO_MEMORY -ErrorAction Ignore
            } else {
                $env:CLAUDE_CODE_DISABLE_AUTO_MEMORY = $previousDisableAutoMemory
            }
        }
    }
    function cyz  { Invoke-ClaudeSafe --safe-mode --model opus   --effort xhigh  --dangerously-skip-permissions @args }
    function cfz  { Invoke-ClaudeSafe --safe-mode --model sonnet --effort xhigh  --dangerously-skip-permissions @args }
    function chz  { Invoke-ClaudeSafe --safe-mode --model haiku  --effort medium --dangerously-skip-permissions @args }
    function cbz  { Invoke-ClaudeSafe --safe-mode --model fable  --effort xhigh  --dangerously-skip-permissions @args }
    function chlz { Invoke-ClaudeSafe --safe-mode --model haiku  --effort low    --dangerously-skip-permissions @args }
    function cfmz { Invoke-ClaudeSafe --safe-mode --model sonnet --effort medium --dangerously-skip-permissions @args }
}

if ($Commands.Codex) {
    # Bare alias tracks Codex's recommended default model + reasoning; suffixes pin the reasoning effort.
    # Values are unquoted: the Windows codex.cmd shim forwards args through cmd.exe (%*), which strips
    # inner quotes anyway, and Codex parses bare values as strings (see its -c help example
    # 'shell_environment_policy.inherit=all'), so the unquoted form is the robust one here.
    function cdx  { codex @args }
    function cdxh { codex -c model_reasoning_effort=high @args }
    function cdxx { codex -c model_reasoning_effort=xhigh @args }
    function cdxm { codex -c model_reasoning_effort=medium @args }
    function cdxl { codex -c model_reasoning_effort=low @args }
    function cdx0 { codex -c model_reasoning_effort=minimal @args }
}

#==================================================================================================
# UTILITY FUNCTIONS
#==================================================================================================

#--------------------------------------------------------------------------------------------------
# Profile & Environment Management
#--------------------------------------------------------------------------------------------------
function reload {
    Remove-Item "$env:TEMP\starship-init-*.ps1", "$env:TEMP\zoxide-init-*.ps1" -ErrorAction Ignore
    . $PROFILE
}
function reload-path {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}
function path { $env:Path -split ';' | Where-Object { $_ } }
function bench {
    if (-not (Get-Command hyperfine -CommandType Application -ErrorAction Ignore)) {
        Write-Host "hyperfine is not installed. Install with: winget install sharkdp.hyperfine"
        return
    }
    $shell = if ($PSVersionTable.PSVersion.Major -ge 6) { 'pwsh' } else { 'powershell' }
    hyperfine --warmup 3 -n 'with profile' "$shell -NoLogo -Command exit" -n 'without profile' "$shell -NoProfile -NoLogo -Command exit"
}

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

# Update PowerShell itself to the latest stable release using the official signed MSI from GitHub.
# Complements 'update' (winget) for machines where PowerShell was not installed through winget.
function Update-PowerShell {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    # Windows PowerShell 5.1 is always on Windows, so only pwsh (6+) needs the platform guard.
    if ($PSVersionTable.PSVersion.Major -ge 6 -and -not $IsWindows) {
        Write-Warning 'Update-PowerShell is only supported on Windows.'
        return
    }

    $releasesApiUri = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'
    $apiHeaders = @{
        'Accept'               = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }

    # Windows PowerShell 5.1 may negotiate TLS 1.0 by default, which GitHub refuses.
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }

    try {
        # The /releases/latest endpoint already excludes drafts and pre-releases.
        $release = Invoke-RestMethod -Uri $releasesApiUri -Headers $apiHeaders -ErrorAction Stop
    } catch {
        Write-Error "Failed to query the latest PowerShell release: $($_.Exception.Message)"
        return
    }

    # Drop the leading 'v' from the tag and any pre-release suffix from the running version before comparing.
    $latestVersion = [version]($release.tag_name -replace '^v', '')
    $currentVersion = [version](($PSVersionTable.PSVersion.ToString() -split '-')[0])

    if ($latestVersion -le $currentVersion) {
        Write-Host "PowerShell is already up to date (v$currentVersion)."
        return
    }

    # Select the installer that matches the host architecture instead of assuming x64.
    $architecture = switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()) {
        'X64'   { 'x64' }
        'Arm64' { 'arm64' }
        'X86'   { 'x86' }
        default {
            Write-Error "Unsupported architecture: $_"
            return
        }
    }

    $assetName = "PowerShell-$latestVersion-win-$architecture.msi"
    $asset = $release.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
    if (-not $asset) {
        Write-Error "No installer named '$assetName' was found in release v$latestVersion."
        return
    }

    if (-not $PSCmdlet.ShouldProcess("PowerShell v$latestVersion", 'Download and install')) {
        return
    }

    $installerPath = Join-Path -Path $env:TEMP -ChildPath $assetName
    try {
        Write-Host "Downloading PowerShell v$latestVersion ($architecture)..."
        # Suppressing the progress stream avoids a large Invoke-WebRequest slowdown on Windows PowerShell 5.1.
        $previousProgress = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        try {
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installerPath -ErrorAction Stop
        } catch {
            Write-Error "Failed to download the installer: $($_.Exception.Message)"
            return
        } finally {
            $ProgressPreference = $previousProgress
        }

        # Verify the MSI carries a valid Authenticode signature from Microsoft before running it elevated.
        $signature = Get-AuthenticodeSignature -FilePath $installerPath
        if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Microsoft Corporation') {
            Write-Error "The downloaded installer failed signature validation (status: $($signature.Status)). Aborting."
            return
        }

        $msiArguments = @(
            '/package', "`"$installerPath`""
            '/passive', '/norestart'
            'ADD_PATH=1'
            'DISABLE_TELEMETRY=1'
            'USE_MU=1'
            'ENABLE_MU=1'
        )

        Write-Host "Installing PowerShell v$latestVersion (administrator approval required)..."
        try {
            $installer = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArguments -Verb RunAs -Wait -PassThru -ErrorAction Stop
        } catch {
            Write-Error "Failed to launch the installer (elevation may have been declined): $($_.Exception.Message)"
            return
        }

        # Standard msiexec exit codes.
        $exitCode = $installer.ExitCode
        if ($null -eq $exitCode) {
            Write-Warning 'The installer did not report an exit code. Verify the PowerShell version manually.'
        } else {
            switch ($exitCode) {
                0       { Write-Host "PowerShell v$latestVersion installed. Restart your shell to use the new version." }
                3010    { Write-Host "PowerShell v$latestVersion installed. A reboot is required to complete the update." }
                1602    { Write-Warning 'Installation was cancelled.' }
                1618    { Write-Warning 'Another installation is already in progress. Try again later.' }
                default { Write-Error "Installation failed with msiexec exit code $exitCode." }
            }
        }
    } finally {
        Remove-Item -Path $installerPath -Force -ErrorAction Ignore
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

# Oh My Posh - Prompt theme engine
# oh-my-posh init pwsh --config "$([Environment]::GetFolderPath('MyDocuments'))\TerminalThemes\oh-my-posh-theme.json" | Invoke-Expression

# Starship - Alternative prompt theme (cached for performance)
if ($Commands.Starship) {
    $ENV:STARSHIP_CONFIG = "$([Environment]::GetFolderPath('MyDocuments'))\TerminalThemes\starship-theme.toml"
    $starshipCache = "$env:TEMP\starship-init-$($PSVersionTable.PSVersion.Major).ps1"
    if (-not (Test-Path $starshipCache)) {
        & starship init powershell --print-full-init | Out-File $starshipCache -Encoding utf8
    }
    . $starshipCache
    function Invoke-Starship-TransientFunction {
        & starship module character
    }
    Enable-TransientPrompt
}

# Zoxide - Smart directory jumper initialization (cached for performance)
if ($Commands.Zoxide) {
    $zoxideCache = "$env:TEMP\zoxide-init-$($PSVersionTable.PSVersion.Major).ps1"
    if (-not (Test-Path $zoxideCache)) {
        & zoxide init powershell | Out-File $zoxideCache -Encoding utf8
    }
    . $zoxideCache
}

# Machine-local overrides — per-machine tweaks live here, keeping this file identical to origin.
# Lives next to $PROFILE (outside the repo), so it is never committed; gitignored as a safety net.
$localProfile = Join-Path -Path $PSScriptRoot -ChildPath 'profile.local.ps1'
if (Test-Path -Path $localProfile) { . $localProfile }