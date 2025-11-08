# Simple Brew Tools

[![CI](https://github.com/yourusername/simple-brew-tools/workflows/CI/badge.svg)](https://github.com/yourusername/simple-brew-tools/actions)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A modern, cross-platform Homebrew management tool with support for both interactive and command-line interfaces.

## Features

### Core Features
- **Cross-Platform Support**: Works on macOS (Intel & Apple Silicon) and Linux
- **Interactive & CLI Modes**: Use menus or command-line arguments
- **Brewfile Support**: Modern package management using Homebrew's official Brewfile format
- **Cask Management**: Install and manage GUI applications (Chrome, Firefox, VS Code, etc.)
- **Smart Backups**: Multiple backup formats (legacy and Brewfile)
- **Color-Coded Output**: Easy-to-read success, warning, and error messages
- **Better Error Handling**: Graceful degradation and detailed error reporting
- **ShellCheck Compliant**: Follows modern shell scripting best practices

### Package Management
1. **Install Homebrew**: Automatically installs Homebrew if not present
2. **Backup & Restore**: Create backups before updates
3. **Brewfile Support**: Generate and restore from Brewfile
4. **Install/Uninstall**: Batch operations from package lists
5. **Update Programs**: Update all installed packages with automatic backup
6. **Rollback**: Restore to previous versions (legacy support)
7. **Health Check**: Run `brew doctor` to check system health
8. **Cleanup**: Remove old versions and free disk space
9. **Search**: Find packages in Homebrew repositories
10. **List Outdated**: Show packages with available updates
11. **Cask Management**: Install and manage GUI applications

## Installation

### Quick Install

```bash
git clone https://github.com/yourusername/simple-brew-tools.git
cd simple-brew-tools
chmod +x brew-tools.sh
```

### System Requirements

- **macOS**: 10.15+ (Catalina or newer)
- **Linux**: Ubuntu 18.04+, Debian 10+, or other systemd-based distributions
- **Bash**: 4.0 or newer

## Usage

### Interactive Mode

Run without arguments to use the interactive menu:

```bash
./brew-tools.sh
```

### Command-Line Mode

Run specific commands directly:

```bash
./brew-tools.sh [COMMAND] [OPTIONS]
```

### Available Commands

| Command | Description |
|---------|-------------|
| `install-homebrew` | Install Homebrew if not already installed |
| `backup` | Backup installed programs (legacy format) |
| `generate-brewfile` | Generate Brewfile (modern format) |
| `install-brewfile` | Install packages from Brewfile |
| `install-programs` | Install programs from brew_programs_list.txt |
| `uninstall-programs` | Uninstall programs from brew_programs_list.txt |
| `update` | Update all installed programs |
| `rollback` | Rollback to previous versions (legacy) |
| `health` | Check Homebrew health |
| `cleanup` | Clean up old Homebrew files |
| `search [PACKAGE]` | Search for a package |
| `outdated` | List outdated packages |
| `list-casks` | List installed casks (GUI apps) |
| `list-formulae` | List installed formulae (CLI tools) |
| `install-cask [CASK]` | Install a cask (GUI application) |
| `interactive` | Run in interactive menu mode |
| `help`, `--help`, `-h` | Show help message |
| `version`, `--version`, `-v` | Show version information |

## Examples

### Basic Operations

```bash
# Show help
./brew-tools.sh --help

# Show version
./brew-tools.sh --version

# Update all packages
./brew-tools.sh update

# Check Homebrew health
./brew-tools.sh health

# Clean up old files
./brew-tools.sh cleanup
```

### Brewfile Operations (Recommended)

```bash
# Generate a Brewfile from your current installation
./brew-tools.sh generate-brewfile

# Install packages from Brewfile
./brew-tools.sh install-brewfile

# The Brewfile can be version controlled and shared across machines
git add Brewfile
git commit -m "Add Brewfile"
```

### Package Management

```bash
# Search for a package
./brew-tools.sh search wget

# Install a GUI application (cask)
./brew-tools.sh install-cask firefox
./brew-tools.sh install-cask visual-studio-code
./brew-tools.sh install-cask google-chrome

# List installed casks
./brew-tools.sh list-casks

# List installed CLI tools
./brew-tools.sh list-formulae

# Show outdated packages
./brew-tools.sh outdated
```

### Legacy Package List Operations

```bash
# Create brew_programs_list.txt with one package per line
cat > brew_programs_list.txt << EOF
wget
curl
git
node
python3
EOF

# Install all packages from the list
./brew-tools.sh install-programs

# Uninstall all packages from the list
./brew-tools.sh uninstall-programs
```

### Backup and Restore

```bash
# Create backup before major changes
./brew-tools.sh backup

# Generate modern Brewfile backup
./brew-tools.sh generate-brewfile

# The update command automatically creates backups
./brew-tools.sh update
```

## File Structure

```
simple-brew-tools/
├── brew-tools.sh              # Main script
├── README.md                  # This file
├── LICENSE                    # License file
├── CHANGELOG.md              # Version history
├── .gitignore                # Git ignore rules
├── .markdownlint.json        # Markdown linting config
├── Brewfile                  # Generated package list (modern)
├── Brewfile.backup           # Backup of previous Brewfile
├── brew_programs_list.txt    # Package list (legacy, not in git)
├── brew_programs_backup.txt  # Backup file (legacy, not in git)
├── tests/
│   ├── README.md            # Test documentation
│   └── test_brew_tools.bats # Automated tests
└── .github/
    └── workflows/
        └── ci.yml           # GitHub Actions CI/CD
```

## Development

### Running Tests

Install bats-core:

```bash
# macOS
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats
```

Run tests:

```bash
bats tests/test_brew_tools.bats
```

### Code Quality

The project uses:
- **ShellCheck**: Static analysis for shell scripts
- **bats-core**: Automated testing framework
- **GitHub Actions**: Continuous integration

Run ShellCheck locally:

```bash
shellcheck brew-tools.sh
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`bats tests/`)
5. Run ShellCheck (`shellcheck brew-tools.sh`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## What's New in v2.0.0

### Phase 1 Updates (2026)

- **Modern Shell Practices**: Added `set -euo pipefail`, proper error handling, and ShellCheck compliance
- **Cross-Platform Support**: Works on macOS (Intel/ARM) and Linux
- **CLI Arguments**: Non-interactive mode with full command support
- **Brewfile Support**: Modern package management with `brew bundle`
- **Cask Support**: Install and manage GUI applications
- **Color Output**: Visual feedback with color-coded messages
- **Improved Logging**: Structured log_info, log_success, log_warning, log_error functions
- **Better Error Handling**: Functions return proper exit codes
- **Automated Testing**: bats-core test suite
- **CI/CD Pipeline**: GitHub Actions for automated testing
- **Enhanced Documentation**: Comprehensive README with examples

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

## Troubleshooting

### Homebrew Not Found After Installation

If brew is not found after installation, try:

```bash
# For Apple Silicon Macs
eval "$(/opt/homebrew/bin/brew shellenv)"

# For Intel Macs
eval "$(/usr/local/bin/brew shellenv)"

# For Linux
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

Add the appropriate line to your shell profile (~/.zshrc or ~/.bashrc).

### Permission Denied

If you get permission denied:

```bash
chmod +x brew-tools.sh
```

### ShellCheck Warnings

The script is designed to pass ShellCheck with no warnings. If you encounter issues:

```bash
shellcheck brew-tools.sh
```

## Roadmap

### Phase 2 (Planned)
- Configuration file support (~/.brew-tools.conf)
- Logging system with rotation
- Parallel package installation
- Enhanced UI with progress bars
- Man page documentation
- Tap management

### Phase 3 (Future)
- Cloud backup sync (S3, Dropbox)
- Multi-machine profiles
- Notification system (email, Slack, Discord)
- Analytics dashboard
- Plugin system

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Homebrew](https://brew.sh/) - The package manager for macOS and Linux
- [bats-core](https://github.com/bats-core/bats-core) - Bash Automated Testing System
- [ShellCheck](https://www.shellcheck.net/) - Shell script analysis tool

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/simple-brew-tools/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/simple-brew-tools/discussions)

## Author

Created and maintained by the Simple Brew Tools community.

---

**Note**: This tool is not affiliated with or endorsed by Homebrew. It's a community tool to help manage Homebrew installations more easily.
