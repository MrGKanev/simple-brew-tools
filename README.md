# Simple Brew Tools Script

This script provides a simple menu interface for managing Homebrew packages.

## Prerequisites

- Ensure you have a macOS system.
- This script requires that you have an internet connection to install Homebrew and any packages.

## Features

1. **Install Homebrew**: Installs Homebrew on your system if it is not already installed.
2. **List Installed Programs**: Generates a list of all installed Homebrew programs and saves it to `brew_programs_list.txt`.
3. **Install Programs**: Installs programs listed in `brew_programs_list.txt` sequentially.
4. **Uninstall Programs**: Uninstalls programs listed in `brew_programs_list.txt` sequentially.
5. **Update Programs**: Updates all installed Homebrew programs.
6. **Check Homebrew Health**: Checks the health of the Homebrew installation.
7. **Clean Up Homebrew**: Cleans up Homebrew by removing old versions of installed programs.

## Usage

### Step 1: Make the Script Executable

```bash
    chmod +x brew-tools.sh
```

### Step 2: Run the Script

```bash
    ./brew-tools.sh
```

