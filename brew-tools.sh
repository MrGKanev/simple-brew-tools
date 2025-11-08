#!/usr/bin/env bash

# Simple Brew Tools - Modern Homebrew Management Script
# Version: 2.0.0
# Updated for 2026

# Safer bash execution
set -euo pipefail

# Global variables
readonly SCRIPT_VERSION="2.0.0"
readonly BACKUP_FILE="brew_programs_backup.txt"
readonly PROGRAMS_LIST_FILE="brew_programs_list.txt"
readonly BREWFILE="Brewfile"
readonly BREWFILE_BACKUP="Brewfile.backup"

# Color codes for better UX
if [[ -t 1 ]]; then
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly BLUE='\033[0;34m'
  readonly NC='\033[0m' # No Color
else
  readonly RED=''
  readonly GREEN=''
  readonly YELLOW=''
  readonly BLUE=''
  readonly NC=''
fi

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Detect platform and set brew path
detect_platform() {
  local brew_path=""

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - check for Apple Silicon or Intel
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
      brew_path="/opt/homebrew/bin/brew"
    elif [[ -x "/usr/local/bin/brew" ]]; then
      brew_path="/usr/local/bin/brew"
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
      brew_path="/home/linuxbrew/.linuxbrew/bin/brew"
    elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
      brew_path="$HOME/.linuxbrew/bin/brew"
    fi
  fi

  echo "$brew_path"
}

# Initialize brew path
init_brew_path() {
  local brew_path
  brew_path=$(detect_platform)

  if [[ -n "$brew_path" ]] && [[ -x "$brew_path" ]]; then
    eval "$("$brew_path" shellenv)"
  fi
}

# Function to install Homebrew
install_homebrew() {
  if command -v brew &> /dev/null; then
    log_info "Homebrew is already installed at $(which brew)"
    brew --version
    return 0
  fi

  log_info "Installing Homebrew..."

  if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    log_error "Failed to install Homebrew"
    return 1
  fi

  # Initialize brew path after installation
  init_brew_path

  if command -v brew &> /dev/null; then
    log_success "Homebrew installed successfully at $(which brew)"
    brew --version
    return 0
  else
    log_error "Homebrew installation completed but brew command not found"
    log_info "You may need to add Homebrew to your PATH manually"
    return 1
  fi
}

# Function to backup installed programs and their versions (legacy format)
backup_installed_programs_and_versions() {
  log_info "Backing up installed programs and their versions to $BACKUP_FILE..."

  if ! brew list --versions > "$BACKUP_FILE"; then
    log_error "Failed to create backup"
    return 1
  fi

  log_success "Backup completed: $BACKUP_FILE ($(wc -l < "$BACKUP_FILE") packages)"
  return 0
}

# Function to generate Brewfile (modern format)
generate_brewfile() {
  log_info "Generating Brewfile..."

  # Backup existing Brewfile if it exists
  if [[ -f "$BREWFILE" ]]; then
    cp "$BREWFILE" "$BREWFILE_BACKUP"
    log_info "Existing Brewfile backed up to $BREWFILE_BACKUP"
  fi

  if ! brew bundle dump --force --file="$BREWFILE"; then
    log_error "Failed to generate Brewfile"
    return 1
  fi

  log_success "Brewfile generated successfully"

  # Show summary
  local taps casks formulae
  taps=$(grep -c "^tap " "$BREWFILE" 2>/dev/null || echo "0")
  formulae=$(grep -c "^brew " "$BREWFILE" 2>/dev/null || echo "0")
  casks=$(grep -c "^cask " "$BREWFILE" 2>/dev/null || echo "0")

  log_info "Brewfile contains: $taps taps, $formulae formulae, $casks casks"
  return 0
}

# Function to install from Brewfile
install_from_brewfile() {
  if [[ ! -f "$BREWFILE" ]]; then
    log_error "Brewfile not found. Generate one first with --generate-brewfile"
    return 1
  fi

  log_info "Installing packages from Brewfile..."

  if ! brew bundle install --file="$BREWFILE"; then
    log_error "Failed to install some packages from Brewfile"
    return 1
  fi

  log_success "All packages from Brewfile installed successfully"
  return 0
}

# Function to install programs from brew_programs_list.txt
install_programs() {
  if [[ ! -f "$PROGRAMS_LIST_FILE" ]]; then
    log_error "File $PROGRAMS_LIST_FILE not found"
    return 1
  fi

  log_info "Installing programs from $PROGRAMS_LIST_FILE..."
  local installed=0
  local skipped=0
  local failed=0

  while IFS= read -r program; do
    # Skip empty lines and comments
    [[ -z "$program" ]] || [[ "$program" =~ ^# ]] && continue

    log_info "Checking if $program is already installed..."
    if brew list --formula "$program" &> /dev/null || brew list --cask "$program" &> /dev/null; then
      log_warning "$program is already installed. Skipping."
      ((skipped++)) || true
    else
      log_info "Installing $program..."
      if brew install "$program"; then
        log_success "$program installed successfully"
        ((installed++)) || true
      else
        log_error "Failed to install $program"
        ((failed++)) || true
      fi
    fi
  done < "$PROGRAMS_LIST_FILE"

  log_info "Installation summary: $installed installed, $skipped skipped, $failed failed"
  return 0
}

# Function to uninstall programs from a file
uninstall_programs() {
  if [[ ! -f "$PROGRAMS_LIST_FILE" ]]; then
    log_error "File $PROGRAMS_LIST_FILE not found"
    return 1
  fi

  log_info "Uninstalling programs from $PROGRAMS_LIST_FILE..."
  local uninstalled=0
  local skipped=0
  local failed=0

  while IFS= read -r program; do
    # Skip empty lines and comments
    [[ -z "$program" ]] || [[ "$program" =~ ^# ]] && continue

    log_info "Checking if $program is installed..."
    if brew list --formula "$program" &> /dev/null || brew list --cask "$program" &> /dev/null; then
      log_info "Uninstalling $program..."
      if brew uninstall "$program"; then
        log_success "$program uninstalled successfully"
        ((uninstalled++)) || true
      else
        log_error "Failed to uninstall $program"
        ((failed++)) || true
      fi
    else
      log_warning "$program is not installed. Skipping."
      ((skipped++)) || true
    fi
  done < "$PROGRAMS_LIST_FILE"

  log_info "Uninstallation summary: $uninstalled uninstalled, $skipped skipped, $failed failed"
  return 0
}

# Function to update all installed Homebrew programs
update_programs() {
  # Create backup before updating
  backup_installed_programs_and_versions
  generate_brewfile

  log_info "Updating Homebrew and all installed programs..."

  if brew update && brew upgrade; then
    log_success "All programs updated successfully"
    return 0
  else
    log_error "Failed to update some programs"
    return 1
  fi
}

# Function to rollback updates to previous versions (legacy)
rollback_updates() {
  if [[ ! -f "$BACKUP_FILE" ]]; then
    log_error "No backup file found ($BACKUP_FILE). Cannot rollback updates."
    return 1
  fi

  log_warning "Rolling back to previous versions is complex and may not work for all packages"
  log_warning "Consider using Brewfile restore instead"
  read -rp "Continue with rollback? [y/N]: " -n 1
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Rollback cancelled"
    return 0
  fi

  log_info "Rolling back to previous versions..."
  local success=0
  local failed=0

  while IFS= read -r line; do
    local program version
    program=$(echo "$line" | awk '{print $1}')
    version=$(echo "$line" | awk '{print $2}')

    log_info "Processing $program@$version..."

    # This is a simplified approach; actual rollback is more complex
    if brew uninstall "$program" 2>/dev/null && brew install "$program"; then
      log_success "$program processed"
      ((success++)) || true
    else
      log_warning "Could not process $program"
      ((failed++)) || true
    fi
  done < "$BACKUP_FILE"

  log_info "Rollback summary: $success successful, $failed failed"
  return 0
}

# Function to check Homebrew health
check_brew_health() {
  log_info "Checking Homebrew health..."
  brew doctor
  return 0
}

# Function to clean up Homebrew
cleanup_brew() {
  log_info "Cleaning up Homebrew..."

  if brew cleanup -s; then
    log_success "Homebrew cleaned up successfully"

    # Show disk space saved
    log_info "Running cleanup dry-run to see what can be cleaned..."
    brew cleanup -n || true
    return 0
  else
    log_error "Failed to clean up Homebrew"
    return 1
  fi
}

# Function to search for a Homebrew package
search_package() {
  local package="${1:-}"

  if [[ -z "$package" ]]; then
    read -rp "Enter the name of the package to search: " package
  fi

  if [[ -z "$package" ]]; then
    log_error "No package name provided"
    return 1
  fi

  log_info "Searching for '$package'..."
  brew search "$package"
  return 0
}

# Function to list outdated Homebrew packages
list_outdated_packages() {
  log_info "Listing all outdated Homebrew packages..."

  local outdated_count
  outdated_count=$(brew outdated | wc -l)

  if [[ "$outdated_count" -eq 0 ]]; then
    log_success "All packages are up to date!"
  else
    brew outdated
    log_info "Total outdated packages: $outdated_count"
  fi

  return 0
}

# Function to list installed casks
list_casks() {
  log_info "Listing installed casks (GUI applications)..."

  local cask_count
  cask_count=$(brew list --cask | wc -l)

  if [[ "$cask_count" -eq 0 ]]; then
    log_info "No casks installed"
  else
    brew list --cask
    log_info "Total casks installed: $cask_count"
  fi

  return 0
}

# Function to list installed formulae
list_formulae() {
  log_info "Listing installed formulae (CLI tools)..."

  local formula_count
  formula_count=$(brew list --formula | wc -l)

  if [[ "$formula_count" -eq 0 ]]; then
    log_info "No formulae installed"
  else
    brew list --formula
    log_info "Total formulae installed: $formula_count"
  fi

  return 0
}

# Function to install a cask
install_cask() {
  local cask="${1:-}"

  if [[ -z "$cask" ]]; then
    read -rp "Enter the name of the cask to install: " cask
  fi

  if [[ -z "$cask" ]]; then
    log_error "No cask name provided"
    return 1
  fi

  log_info "Installing cask: $cask..."

  if brew install --cask "$cask"; then
    log_success "Cask $cask installed successfully"
    return 0
  else
    log_error "Failed to install cask $cask"
    return 1
  fi
}

# Function to show help
show_help() {
  cat << EOF
Simple Brew Tools v${SCRIPT_VERSION} - Modern Homebrew Management

USAGE:
    $(basename "$0") [COMMAND] [OPTIONS]

COMMANDS:
    install-homebrew              Install Homebrew if not already installed
    backup                        Backup installed programs (legacy format)
    generate-brewfile             Generate Brewfile (modern format)
    install-brewfile              Install packages from Brewfile
    install-programs              Install programs from $PROGRAMS_LIST_FILE
    uninstall-programs            Uninstall programs from $PROGRAMS_LIST_FILE
    update                        Update all installed programs
    rollback                      Rollback to previous versions (legacy)
    health                        Check Homebrew health
    cleanup                       Clean up old Homebrew files
    search [PACKAGE]              Search for a package
    outdated                      List outdated packages
    list-casks                    List installed casks (GUI apps)
    list-formulae                 List installed formulae (CLI tools)
    install-cask [CASK]           Install a cask (GUI application)
    interactive                   Run in interactive menu mode (default)
    help, --help, -h              Show this help message
    version, --version, -v        Show version information

EXAMPLES:
    $(basename "$0")                          # Run in interactive mode
    $(basename "$0") update                   # Update all packages
    $(basename "$0") generate-brewfile        # Generate Brewfile
    $(basename "$0") search wget              # Search for wget
    $(basename "$0") install-cask firefox     # Install Firefox

FILES:
    $BREWFILE                   Modern package list (brew bundle format)
    $PROGRAMS_LIST_FILE         Legacy package list (one per line)
    $BACKUP_FILE    Legacy backup file

For more information, visit: https://github.com/MrGKanev/simple-brew-tools
EOF
}

# Function to show version
show_version() {
  echo "Simple Brew Tools v${SCRIPT_VERSION}"
  echo "Updated for 2026"
  if command -v brew &> /dev/null; then
    echo ""
    brew --version
  fi
}

# Interactive menu
show_menu() {
  echo ""
  echo "========================================="
  echo "  Simple Brew Tools v${SCRIPT_VERSION}"
  echo "========================================="
  echo ""
  echo "Select an option:"
  echo ""
  echo " 1.  Install Homebrew"
  echo " 2.  Backup installed programs (legacy)"
  echo " 3.  Generate Brewfile (modern)"
  echo " 4.  Install from Brewfile"
  echo " 5.  Install programs from $PROGRAMS_LIST_FILE"
  echo " 6.  Uninstall programs from $PROGRAMS_LIST_FILE"
  echo " 7.  Update all installed programs"
  echo " 8.  Rollback updates (legacy)"
  echo " 9.  Check Homebrew health"
  echo " 10. Clean up Homebrew"
  echo " 11. Search for a package"
  echo " 12. List outdated packages"
  echo " 13. List installed casks (GUI apps)"
  echo " 14. List installed formulae (CLI tools)"
  echo " 15. Install a cask (GUI app)"
  echo " 16. Exit"
  echo ""
  read -rp "Enter your choice [1-16]: " choice

  case $choice in
    1)  install_homebrew ;;
    2)  backup_installed_programs_and_versions ;;
    3)  generate_brewfile ;;
    4)  install_from_brewfile ;;
    5)  install_programs ;;
    6)  uninstall_programs ;;
    7)  update_programs ;;
    8)  rollback_updates ;;
    9)  check_brew_health ;;
    10) cleanup_brew ;;
    11) search_package ;;
    12) list_outdated_packages ;;
    13) list_casks ;;
    14) list_formulae ;;
    15) install_cask ;;
    16) log_info "Exiting..."; exit 0 ;;
    *)  log_error "Invalid choice. Please select 1-16."; return 1 ;;
  esac
}

# Main function
main() {
  # Initialize brew path if installed
  init_brew_path

  # Parse command line arguments
  if [[ $# -eq 0 ]]; then
    # Interactive mode
    while true; do
      show_menu
      echo ""
      read -rp "Press Enter to continue or Ctrl+C to exit..."
    done
  else
    # Non-interactive mode
    case "${1:-}" in
      install-homebrew)
        install_homebrew
        ;;
      backup)
        backup_installed_programs_and_versions
        ;;
      generate-brewfile)
        generate_brewfile
        ;;
      install-brewfile)
        install_from_brewfile
        ;;
      install-programs)
        install_programs
        ;;
      uninstall-programs)
        uninstall_programs
        ;;
      update)
        update_programs
        ;;
      rollback)
        rollback_updates
        ;;
      health)
        check_brew_health
        ;;
      cleanup)
        cleanup_brew
        ;;
      search)
        search_package "${2:-}"
        ;;
      outdated)
        list_outdated_packages
        ;;
      list-casks)
        list_casks
        ;;
      list-formulae)
        list_formulae
        ;;
      install-cask)
        install_cask "${2:-}"
        ;;
      interactive)
        while true; do
          show_menu
          echo ""
          read -rp "Press Enter to continue or Ctrl+C to exit..."
        done
        ;;
      help|--help|-h)
        show_help
        ;;
      version|--version|-v)
        show_version
        ;;
      *)
        log_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
    esac
  fi
}

# Run main function
main "$@"
