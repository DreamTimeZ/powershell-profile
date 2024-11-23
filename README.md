# PowerShell Profile

## Table of Content

1. [Preview](#preview)
2. [Overview](#overview)
3. [Features](#features)
4. [Installation](#installation)
    - [What the Installation Does](#what-the-installation-does)
    - [Installation Scripts](#installation-scripts)
        - [bat Files](#bat-files)
        - [ps1 Files](#ps1-files)
5. [Usage](#usage)
    - [Aliases](#aliases)
    - [Functions](#functions)
6. [Uninstallation](#uninstallation)

## Preview

![Preview](preview.png)

A demonstration of the customized PowerShell, pwsh terminal in action, featuring aliases and themed appearance.

## Overview

This repository provides my `PowerShell` and `pwsh` profile designed to enhance your terminal experience. The included scripts make it quick and easy to set up the profile along with necessary dependencies and themes.

A collection of PowerShell functions and aliases for enhanced productivity.

## Features

- Custom aliases (`vi`, `cd`, `touch`, etc.)
- Fuzzy directory navigation with `fzf`
- Text search (`grep`)
- System management (shutdown, reboot, process kill)
- IP address discovery (IPv4/IPv6)
- Package management (`winget`)
- Command history and search
- System uptime display

---

## Installation

### What the Installation Does

1. **Dependencies**: Installs required packages using the Windows Package Manager (`winget`).
2. **Themes**: Clones the [terminal-themes](https://github.com/DreamTimeZ/terminal-themes) repository into your `Documents` folder under the directory `TerminalThemes`.
3. **Profile Setup**: Copies the PowerShell profile file to the appropriate location as specified by the `$PROFILE.CurrentUserCurrentHost` variable (configured in the `install.ps1` script).

### Profile Location Details

- The profile is installed to the location specified by `$PROFILE.CurrentUserCurrentHost`.
- If you are running the script in a `pwsh` terminal, the profile path for `pwsh` will be used.
- To view all profile locations, run the following command:

    ```powershell
    $PROFILE | Select-Object *
    ```

### Installation Scripts

You can use the provided scripts to quickly install or uninstall the profile:

#### bat Files

- Double-click the `.bat` files to run the installation (`install.bat`) or uninstallation (`uninstall.bat`).
- **Note**: `.bat` scripts cannot be executed inside a `pwsh` terminal because they start a new PowerShell subprocess. To use them in `pwsh`, edit the `.bat` files and replace `powershell` with `pwsh`.

#### ps1 Files

- Run the `.ps1` scripts (e.g., `install.ps1` or `uninstall.ps1`) in either Windows PowerShell or `pwsh`.
- Alternatively, right-click the `.ps1` file and select "Run with PowerShell.

#### After Running the Script to make it work

```powershell
& $PROFILE
```

- Or restart the terminal

## Usage

### Aliases

- `vi`: Open Neovim
- `touch`: Create a new file
- `cd`: Use `zoxide`
- `ls`: File listing (`eza`)

### Functions

- `cdf`: Change directory using `fzf`
- `grep`: Search text (pipeline/input)
- `pkill`: Kill a process by name
- `poweroff`: Shutdown system
- `reboot`: Reboot system
- `IPv4`/`IPv6`: Get local/public IPs or domain IP
- `update`: Update packages via `winget`
- `uptime`: Show system uptime
- `hist`: Display command history
- `gcmd`: Search commands
- `n`: Open files in Notepad

## Uninstallation

Follow the same process as installation, using the corresponding `uninstall.bat` or `uninstall.ps1` scripts.

---

Feel free to raise issues or contribute to this project!
