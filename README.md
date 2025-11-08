# Simple Brew Tools

[![CI](https://github.com/MrGKanev/simple-brew-tools/workflows/CI/badge.svg)](https://github.com/MrGKanev/simple-brew-tools/actions)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A modern, cross-platform Homebrew management tool with support for both interactive and command-line interfaces.

## Features

- **Cross-Platform**: Works on macOS (Intel & Apple Silicon) and Linux
- **Interactive & CLI Modes**: Use menus or run commands directly
- **Brewfile Support**: Modern package management with Homebrew's Brewfile format
- **Cask Management**: Install and manage GUI applications
- **Smart Backups**: Automatic backups before updates
- **Color-Coded Output**: Clear visual feedback
- **ShellCheck Compliant**: Follows modern shell scripting best practices

## Installation

```bash
git clone https://github.com/MrGKanev/simple-brew-tools.git
cd simple-brew-tools
chmod +x brew-tools.sh
```

## Quick Start

### Interactive Mode

```bash
./brew-tools.sh
```

### Command-Line Mode

```bash
./brew-tools.sh [COMMAND] [OPTIONS]
```

## Available Commands

| Command | Description |
|---------|-------------|
| `install-homebrew` | Install Homebrew if not present |
| `backup` | Backup installed programs |
| `generate-brewfile` | Generate Brewfile from current installation |
| `install-brewfile` | Install packages from Brewfile |
| `update` | Update all packages |
| `cleanup` | Clean up old files |
| `health` | Check Homebrew health |
| `search [PACKAGE]` | Search for a package |
| `outdated` | List outdated packages |
| `list-casks` | List installed GUI apps |
| `list-formulae` | List installed CLI tools |
| `install-cask [CASK]` | Install a GUI application |
| `help`, `--help`, `-h` | Show help |
| `version`, `--version`, `-v` | Show version |

## Usage Examples

```bash
# Update all packages
./brew-tools.sh update

# Generate Brewfile (recommended for backups)
./brew-tools.sh generate-brewfile

# Install a GUI application
./brew-tools.sh install-cask firefox

# Search for a package
./brew-tools.sh search wget

# List outdated packages
./brew-tools.sh outdated
```

## Brewfile Workflow (Recommended)

The modern way to manage packages:

```bash
# Export your current setup
./brew-tools.sh generate-brewfile

# Version control it
git add Brewfile
git commit -m "Add Brewfile"

# Restore on another machine
./brew-tools.sh install-brewfile
```

## Development

### Running Tests

```bash
# Install bats-core
brew install bats-core  # macOS
sudo apt-get install bats  # Linux

# Run tests
bats tests/test_brew_tools.bats
```

### Code Quality

```bash
# Run ShellCheck
shellcheck brew-tools.sh
```

## What's New in v2.0.0

- Modern shell practices with `set -euo pipefail` and ShellCheck compliance
- Cross-platform support (macOS Intel/ARM, Linux)
- CLI arguments for non-interactive use
- Brewfile support for modern package management
- Cask support for GUI applications
- Color-coded output with better error messages
- Automated testing with bats-core
- CI/CD pipeline with GitHub Actions

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/MrGKanev/simple-brew-tools/issues)
- **Discussions**: [GitHub Discussions](https://github.com/MrGKanev/simple-brew-tools/discussions)
