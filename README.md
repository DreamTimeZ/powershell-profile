# PowerShell Profile

## Table of Contents

1. [Preview](#preview)
2. [Overview](#overview)
3. [Features](#features)
4. [Installation](#installation)
5. [Usage](#usage)
6. [Uninstallation](#uninstallation)

## Preview   
![Preview](preview.png)

## Overview

Customized PowerShell profile with enhanced productivity features, modern tools integration, and themed appearance. Supports both Windows PowerShell and pwsh with automated installation via symlinks for seamless updates.

## Features

### Tool Integration
- **EZA**: Modern `ls` replacement with icons and color
- **Zoxide**: Smart directory navigation (`cd`, `cdi`)
- **Oh My Posh**: Customizable prompt themes
- **Git**: Comprehensive git aliases and shortcuts
- **Poetry**: Python dependency management shortcuts
- **Docker**: Container management aliases

### Custom Functions
- **Navigation**: `..`, `...`, `....` for quick directory traversal
- **System Management**: `poweroff`, `reboot`, `pkill`
- **Network**: `IPv4`, `IPv6` - Get local/public IPs or domain resolution
- **Package Management**: `update` - Bulk update via winget
- **Utilities**: `grep`, `uptime`, `hist`, `gcmd`, `reload`

### Application Launchers
- Neovim, Notepad, Obsidian, Firefox, Docker Desktop, Ollama

## Installation

### Quick Start

```powershell
.\install.bat  # Installs for current user & shell (-Profile current -Shell current)
```

Auto-detects PowerShell (prefers pwsh), installs dependencies via winget (eza, zoxide, Oh My Posh, Neovim, Git, fzf, Starship), clones [terminal-themes](https://github.com/DreamTimeZ/terminal-themes), and creates a profile symlink (requires UAC). Restart terminal or run `& $PROFILE` to activate.

### Configuration Options

```powershell
# Profile Scope
-Profile current      # Current user, current host (default)
-Profile all-hosts    # Current user, all hosts
-Profile all-users    # All users, current host (admin required)
-Profile global       # All users, all hosts (admin required)

# Shell Target
-Shell current        # Auto-detect current shell (default)
-Shell windows        # Windows PowerShell 5.1
-Shell pwsh           # PowerShell 7+
-Shell both           # Both shells

# Examples
.\install.bat -Profile current -Shell both
.\install.bat -Profile all-hosts -Shell pwsh
```

## Usage

### File & Directory Operations
```powershell
ls                    # List files with eza
la                    # List all files with icons
ll                    # Long listing with icons
lla                   # Long listing including hidden
tree                  # Tree view (2 levels)
touch file.txt        # Create new file
cd project            # Smart jump with zoxide
cdi                   # Interactive directory picker
..                    # Go up one directory
...                   # Go up two directories
```

### Git Shortcuts
```powershell
gs                    # git status
ga                    # git add . && git status
gcom "message"        # git commit -m
gpsh                  # git push
gpl                   # git pull
gsw branch            # git switch
gswc new-branch       # git switch -c (create new)
glg                   # git log graph
gdf                   # git diff
```

### Python (Poetry)
```powershell
pi                    # poetry install
pa package            # poetry add
prun                  # poetry run
prp script.py         # poetry run python
ptest                 # poetry run pytest
```

### System & Network
```powershell
IPv4                  # Show local & public IPv4
IPv6                  # Show local & public IPv6
IPv4 -d google.com    # Resolve domain to IPv4
update                # Update all winget packages
uptime                # System uptime
pkill processname     # Kill process by name
poweroff              # Shutdown
reboot                # Restart
```

### Docker
```powershell
d                     # docker
dps                   # docker ps
di                    # docker images
dex container bash    # docker exec -it
```

### Utilities
```powershell
reload                # Reload profile
hist                  # Full command history
gcmd keyword          # Search for commands
grep pattern          # Search in pipeline
n file.txt            # Open in Notepad
vi file.txt           # Open in Neovim
```

## Uninstallation

```powershell
.\uninstall.ps1  # Supports same -Profile and -Shell parameters
.\uninstall.ps1 -Profile current -Shell both
Get-Help .\uninstall.ps1 -Detailed
```

Prompts to remove packages, themes, and profile symlinks.

---

**Questions or contributions?** Feel free to raise issues or submit pull requests!
