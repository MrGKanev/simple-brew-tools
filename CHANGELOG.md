# Changelog

All notable changes to Simple Brew Tools will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-01-XX

### Added - Phase 1 Modernization

#### Core Improvements
- **Cross-Platform Support**: Now supports macOS (both Intel and Apple Silicon) and Linux
- **Platform Detection**: Automatic detection of Homebrew installation paths for different platforms
- **CLI Argument Parsing**: Full non-interactive mode with command-line arguments
- **Help System**: Comprehensive `--help` and `-h` flags with detailed usage information
- **Version Command**: Added `--version` and `-v` flags to show version information

#### Features
- **Brewfile Support**: Generate and install from Brewfile (modern Homebrew bundle format)
  - `generate-brewfile` command to create Brewfile from current installation
  - `install-brewfile` command to restore packages from Brewfile
  - Automatic Brewfile backup before regeneration
  - Summary statistics (taps, formulae, casks count)
- **Cask Management**: Full support for GUI application management
  - `install-cask` command to install GUI applications
  - `list-casks` command to show installed casks
  - Cask detection in install/uninstall operations
- **Enhanced Package Operations**:
  - `list-formulae` command to show installed CLI tools
  - Support for comments in `brew_programs_list.txt` (lines starting with #)
  - Installation/uninstallation summary statistics
  - Better package existence checking for both formulae and casks

#### User Experience
- **Color-Coded Output**: Visual feedback with colors
  - Blue for informational messages
  - Green for success messages
  - Yellow for warnings
  - Red for errors
- **Structured Logging**: Consistent log functions (`log_info`, `log_success`, `log_warning`, `log_error`)
- **Better Interactive Menu**: Improved menu with clear organization and exit option
- **Progress Feedback**: Shows counts and summaries for operations

#### Code Quality
- **ShellCheck Compliance**: Script passes ShellCheck with no warnings
- **Modern Shell Practices**:
  - Added `set -euo pipefail` for safer execution
  - Use of `[[ ]]` instead of `[ ]` for conditionals
  - Proper variable quoting throughout
  - Readonly variables for constants
  - Local variables in functions
- **Error Handling**:
  - Functions return proper exit codes (0 for success, 1 for failure)
  - Graceful degradation instead of hard exits
  - Better error messages with context
  - Non-fatal errors in batch operations

#### Testing & CI/CD
- **Automated Testing**: bats-core test suite
  - Tests for script existence and executability
  - Help and version flag tests
  - Command-line argument parsing tests
  - Bash syntax validation
  - ShellCheck integration test
- **GitHub Actions CI/CD**:
  - ShellCheck validation on every commit
  - Tests run on Ubuntu and macOS
  - Project structure validation
  - Markdown linting
- **Test Documentation**: README in tests directory

#### Documentation
- **Comprehensive README**: Complete rewrite with:
  - Feature overview with examples
  - Installation instructions
  - Usage guide for both interactive and CLI modes
  - Command reference table
  - Extensive examples for common workflows
  - Troubleshooting section
  - Development guide
  - Roadmap for future phases
- **Code Comments**: Improved inline documentation
- **Test Documentation**: Separate README for testing

#### Configuration
- **Enhanced .gitignore**: Excludes temporary files, backups, logs, and IDE files
- **Markdown Linting**: Added `.markdownlint.json` configuration

### Changed

#### Breaking Changes
- Script now uses `set -euo pipefail`, which may affect error handling in edge cases
- Some command outputs now include color codes (can be disabled by piping or redirecting)

#### Improvements
- **Update Command**: Now automatically creates both legacy backup and Brewfile
- **Rollback Command**: Added warning about complexity and suggestion to use Brewfile
- **Cleanup Command**: Added dry-run output after cleanup to show what can be cleaned
- **Search Command**: Can accept package name as argument or prompt interactively
- **Install Cask Command**: Can accept cask name as argument or prompt interactively
- **Outdated Command**: Shows count of outdated packages
- **List Commands**: Show counts of installed packages

#### Technical Improvements
- All functions now use proper return codes instead of exits
- Better subprocess handling and error propagation
- Improved file existence checking
- Better platform-specific path handling
- More robust installation verification

### Fixed
- Fixed issues with hard-coded Homebrew paths (now supports multiple platforms)
- Fixed error handling that would exit script prematurely
- Fixed package checking to support both formulae and casks
- Fixed silent failures in batch operations
- Fixed shellcheck warnings and style issues

### Security
- Better input sanitization
- Proper quoting to prevent word splitting and globbing issues
- No use of `eval` with untrusted data
- Safer error handling with `set -euo pipefail`

## [1.0.0] - Previous Version

### Features
- Basic Homebrew installation
- Install/uninstall programs from list file
- Backup and restore functionality
- Update all programs
- Rollback updates
- Health check
- Cleanup
- Search packages
- List outdated packages
- Interactive menu interface

---

## Upgrade Guide

### From 1.x to 2.0.0

1. **Test the new script** in interactive mode first to familiarize yourself with changes
2. **Generate a Brewfile** with `./brew-tools.sh generate-brewfile` to adopt modern package management
3. **Update your workflows** to use CLI arguments instead of relying solely on interactive mode
4. **Review your backup strategy** - consider using Brewfile instead of legacy backups
5. **Check platform compatibility** - the script now works on Linux as well as macOS

### New Recommended Workflow

Instead of maintaining `brew_programs_list.txt`, use Brewfile:

```bash
# Generate Brewfile from current installation
./brew-tools.sh generate-brewfile

# Version control it
git add Brewfile
git commit -m "Add Brewfile"

# On a new machine or after reinstall
./brew-tools.sh install-brewfile
```

---

## Future Releases

See the Roadmap section in README.md for planned features in Phase 2 and Phase 3.

[2.0.0]: https://github.com/yourusername/simple-brew-tools/releases/tag/v2.0.0
[1.0.0]: https://github.com/yourusername/simple-brew-tools/releases/tag/v1.0.0
