#!/usr/bin/env bash

# Simple Brew Tools - Modern Homebrew Management Script
# Version: 2.1.0
# Updated for 2026

# Safer bash execution
set -euo pipefail

# Global variables
readonly SCRIPT_VERSION="2.1.0"
BACKUP_FILE="${BACKUP_FILE:-brew_programs_backup.txt}"
PROGRAMS_LIST_FILE="${PROGRAMS_LIST_FILE:-brew_programs_list.txt}"
BREWFILE="${BREWFILE:-Brewfile}"
BREWFILE_BACKUP="${BREWFILE_BACKUP:-Brewfile.backup}"

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

# Verbose/debug mode
VERBOSE="${VERBOSE:-false}"

# Logging functions
log_debug() {
  if [[ "$VERBOSE" == "true" ]]; then
    echo -e "${BLUE}[DEBUG]${NC} $*" >&2
  fi
}

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

absolute_path() {
  printf '%s/%s\n' "$(cd "$(dirname "$1")" && pwd -P)" "$(basename "$1")"
}

open_folder() {
  local folder="${1%/*}"
  [[ "$folder" != "$1" ]] || folder="."
  if [[ "$OSTYPE" == darwin* ]] && command -v open &> /dev/null; then
    open "$folder"
  elif [[ "$OSTYPE" == linux* ]] && command -v xdg-open &> /dev/null; then
    xdg-open "$folder"
  else
    log_warning "Cannot open folders automatically (install xdg-utils on Linux)"
    return 1
  fi
}

show_generated_file() {
  local file_path folder_url entries size reply
  file_path="$(absolute_path "$1")"
  folder_url="file://${file_path%/*}"
  folder_url="${folder_url//%/%25}"
  folder_url="${folder_url// /%20}"
  log_info "Generated file: $file_path"
  if [[ -f "$1" ]]; then
    size=$(wc -c < "$1" | tr -d ' ')
    entries=$(grep -cve '^[[:space:]]*$' -e '^[[:space:]]*#' "$1" || true)
    log_info "Contents: $entries entries, $size bytes"
  fi
  log_info "Open folder: $folder_url"
  if [[ -t 0 && -t 1 ]]; then
    read -rp "Open the folder now? [y/N]: " reply
    [[ "$reply" =~ ^[Yy]$ ]] && open_folder "$file_path"
  fi
}

show_generated_files() {
  local file found=false
  for file in "$BREWFILE" "$BREWFILE_BACKUP" "$BACKUP_FILE" "$HOME/.Brewfile"; do
    [[ -f "$file" ]] || continue
    found=true
    log_info "$(absolute_path "$file") ($(wc -c < "$file" | tr -d ' ') bytes, modified $(date -r "$file" '+%Y-%m-%d %H:%M' 2>/dev/null || stat -c '%y' "$file" | cut -d. -f1))"
  done
  [[ "$found" == true ]] || log_info "No generated files found"
}

# Load configuration from .brew-tools.conf if it exists
load_config() {
  local config_file="${1:-.brew-tools.conf}"

  if [[ ! -f "$config_file" ]]; then
    log_debug "No config file found at $config_file"
    return 0
  fi

  log_debug "Loading config from $config_file"

  while IFS='=' read -r key value; do
    # Skip empty lines and comments
    [[ -z "$key" ]] || [[ "$key" =~ ^[[:space:]]*# ]] && continue
    # Trim whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)

    case "$key" in
      BACKUP_FILE)      BACKUP_FILE="$value" ;;
      PROGRAMS_LIST_FILE) PROGRAMS_LIST_FILE="$value" ;;
      BREWFILE)         BREWFILE="$value" ;;
      BREWFILE_BACKUP)  BREWFILE_BACKUP="$value" ;;
      VERBOSE)          VERBOSE="$value" ;;
      *)                log_warning "Unknown config key: $key" ;;
    esac
  done < "$config_file"

  log_debug "Config loaded: BACKUP_FILE=$BACKUP_FILE, PROGRAMS_LIST_FILE=$PROGRAMS_LIST_FILE, BREWFILE=$BREWFILE"
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
  command -v brew &> /dev/null && return 0

  local brew_path
  brew_path=$(detect_platform)

  if [[ -n "$brew_path" ]] && [[ -x "$brew_path" ]]; then
    # eval is required here: brew shellenv outputs export statements
    # that must be evaluated to set PATH and other env vars in this shell
    eval "$("$brew_path" shellenv)"
  fi
}

# Require brew to be installed (call before brew-dependent operations)
require_brew() {
  if ! command -v brew &> /dev/null; then
    log_error "Homebrew is not installed. Run: $(basename "$0") install-homebrew"
    exit 1
  fi
}

# Cleanup handler for script interruption
cleanup_on_exit() {
  # Restore terminal state if needed
  tput cnorm 2>/dev/null || true
  # Remove any temp files created during this session
  if [[ -n "${BREW_TOOLS_TMPDIR:-}" ]] && [[ -d "$BREW_TOOLS_TMPDIR" ]]; then
    rm -rf "$BREW_TOOLS_TMPDIR"
  fi
}
trap cleanup_on_exit EXIT INT TERM

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
  require_brew
  log_info "Backing up installed programs and their versions to $BACKUP_FILE..."

  if ! brew list --versions > "$BACKUP_FILE"; then
    log_error "Failed to create backup"
    return 1
  fi

  log_success "Backup completed: $BACKUP_FILE ($(wc -l < "$BACKUP_FILE" | tr -d ' ') packages)"
  show_generated_file "$BACKUP_FILE"
  return 0
}

# Function to generate Brewfile (modern format)
generate_brewfile() {
  require_brew
  local global=false no_describe=false custom_file=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --global) global=true ;;
      --no-describe) no_describe=true ;;
      --file) [[ $# -gt 1 ]] || { log_error "--file requires a path"; return 1; }; BREWFILE="$2"; custom_file=true; shift ;;
      --file=*) BREWFILE="${1#*=}"; custom_file=true ;;
      *) log_error "Unknown export option: $1"; return 1 ;;
    esac
    shift
  done
  [[ "$global" == false || "$custom_file" == false ]] || { log_error "--global and --file cannot be combined"; return 1; }
  log_info "Generating Brewfile..."

  local args=(bundle dump --force)
  [[ "$no_describe" == true ]] && args+=(--no-describe)

  if [[ "$global" == true ]]; then
    local snapshot
    snapshot=$(brew "${args[@]}" --file=-)
    if [[ -n "$snapshot" ]] && brew "${args[@]}" --global; then
      log_success "Global Brewfile generated successfully"
      show_generated_file "$HOME/.Brewfile"
      return 0
    fi
    log_error "Failed to generate a non-empty global Brewfile"
    return 1
  fi

  # Backup existing Brewfile if it exists
  [[ "$custom_file" == false ]] || BREWFILE_BACKUP="${BREWFILE}.backup"
  if [[ -f "$BREWFILE" ]]; then
    cp "$BREWFILE" "$BREWFILE_BACKUP"
    log_info "Previous file backed up to: $(absolute_path "$BREWFILE_BACKUP")"
  fi

  if ! brew "${args[@]}" --file="$BREWFILE"; then
    log_error "Failed to generate Brewfile"
    return 1
  fi

  if [[ ! -s "$BREWFILE" ]]; then
    log_error "Generated Brewfile is empty"
    return 1
  fi

  log_success "Brewfile generated successfully"
  show_generated_file "$BREWFILE"

  return 0
}

# Function to install from Brewfile
install_from_brewfile() {
  require_brew
  local check_first=false
  local args=(bundle install --verbose)
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-upgrade) args+=(--no-upgrade) ;;
      --check-first) check_first=true ;;
      --file) [[ $# -gt 1 ]] || { log_error "--file requires a path"; return 1; }; BREWFILE="$2"; shift ;;
      --file=*) BREWFILE="${1#*=}" ;;
      *) log_error "Unknown restore option: $1"; return 1 ;;
    esac
    shift
  done
  if [[ ! -f "$BREWFILE" ]]; then
    log_error "Brewfile not found. Generate one first with: $(basename "$0") export"
    return 1
  fi

  log_info "Installing packages from Brewfile (live details enabled)..."
  log_info "Downloads or builds may take several minutes. If Password appears, macOS needs your administrator password for the cask currently shown."
  log_debug "Using Brewfile: $(realpath "$BREWFILE" 2>/dev/null || echo "$BREWFILE")"

  if [[ "$check_first" == true ]] && ! brew bundle check --verbose --file="$BREWFILE"; then
    read -rp "Continue with restore? [y/N]: " reply
    [[ "$reply" =~ ^[Yy]$ ]] || { log_info "Restore cancelled"; return 0; }
  fi

  if brew "${args[@]}" --file="$BREWFILE"; then
    log_success "All packages from Brewfile installed successfully"
    log_info "Restore summary: all Brewfile dependencies are satisfied"
    notify_completion "Brewfile restore completed"
  else
    log_error "Some packages from Brewfile failed to install (see above)"
    log_info "Restore summary: one or more dependencies failed"
    notify_completion "Brewfile restore finished with errors"
    return 1
  fi

  return 0
}

check_brewfile() {
  require_brew
  [[ "${1:-}" != --file=* ]] || BREWFILE="${1#*=}"
  [[ -f "$BREWFILE" ]] || { log_error "Brewfile not found: $BREWFILE"; return 1; }
  brew bundle check --verbose --file="$BREWFILE"
}

cleanup_brewfile() {
  require_brew
  [[ "${1:-}" != --file=* ]] || BREWFILE="${1#*=}"
  [[ -f "$BREWFILE" ]] || { log_error "Brewfile not found: $BREWFILE"; return 1; }
  brew bundle cleanup --file="$BREWFILE"
}

migrate() {
  command -v brew &> /dev/null || install_homebrew
  install_from_brewfile "$@"
}

show_status() {
  require_brew
  brew --version | head -1
  log_info "$(brew list --formula | wc -l | tr -d ' ') formulae, $(brew list --cask | wc -l | tr -d ' ') casks"
  brew outdated
  [[ ! -f "$BREWFILE" ]] || brew bundle check --verbose --file="$BREWFILE" || true
}

show_completion() {
  local commands="install-homebrew backup export restore check cleanup-brewfile migrate status files open health doctor cleanup cleanup-preview search info info-select outdated upgrade-select list list-casks list-formulae install-cask open-select uninstall-select reinstall help version"
  case "${1:-}" in
    bash) printf 'complete -W %q brew-tools.sh\n' "$commands" ;;
    zsh) printf '#compdef brew-tools.sh\n_arguments "1:command:(%s)"\n' "$commands" ;;
    *) log_error "Usage: $(basename "$0") completion bash|zsh"; return 1 ;;
  esac
}

# Function to install programs from brew_programs_list.txt
install_programs() {
  require_brew
  if [[ ! -f "$PROGRAMS_LIST_FILE" ]]; then
    log_error "File $PROGRAMS_LIST_FILE not found"
    return 1
  fi

  log_info "Installing programs from $PROGRAMS_LIST_FILE..."
  log_debug "Reading program list from: $(realpath "$PROGRAMS_LIST_FILE" 2>/dev/null || echo "$PROGRAMS_LIST_FILE")"
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
  notify_completion "$installed installed, $skipped skipped, $failed failed"
  return 0
}

# Function to uninstall programs from a file
uninstall_programs() {
  require_brew
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

pick_items() {
  [[ "$OSTYPE" == darwin* ]] && command -v osascript &>/dev/null || {
    log_error "Mouse selection is currently available on macOS only"
    return 1
  }
  local title="$1" prompt="$2"
  shift 2
  osascript - "$title" "$prompt" "$@" <<'APPLESCRIPT'
on run arguments
  set dialogTitle to item 1 of arguments
  set dialogPrompt to item 2 of arguments
  set choices to items 3 thru -1 of arguments
  set chosen to choose from list choices with title dialogTitle with prompt dialogPrompt with multiple selections allowed
  if chosen is false then return ""
  set text item delimiters of AppleScript to linefeed
  return chosen as text
end run
APPLESCRIPT
}

notify_completion() {
  [[ "$OSTYPE" == darwin* ]] && command -v osascript &>/dev/null || return 0
  osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title "Simple Brew Tools"' -e 'end run' "$1" &>/dev/null || true
}

uninstall_selected() {
  require_brew

  local packages=() item selected reply uninstalled=0 failed=0
  while IFS= read -r item; do packages+=("Formula: $item"); done < <(brew list --formula)
  while IFS= read -r item; do packages+=("Cask: $item"); done < <(brew list --cask)
  ((${#packages[@]})) || { log_info "No Homebrew packages are installed"; return 0; }

  selected=$(pick_items "Uninstall Homebrew packages" "Select one or more packages:" "${packages[@]}") || return 1
  [[ -n "$selected" ]] || { log_info "Uninstall cancelled"; return 0; }

  printf 'Selected:\n%s\n' "$selected"
  read -rp "Uninstall these packages? [y/N]: " reply
  [[ "$reply" =~ ^[Yy]$ ]] || { log_info "Uninstall cancelled"; return 0; }

  while IFS= read -r item; do
    if [[ "$item" == "Cask: "* ]]; then
      if brew uninstall --cask "${item#Cask: }"; then ((uninstalled++)) || true; else ((failed++)) || true; fi
    else
      if brew uninstall --formula "${item#Formula: }"; then ((uninstalled++)) || true; else ((failed++)) || true; fi
    fi
  done <<< "$selected"

  log_info "Uninstallation summary: $uninstalled uninstalled, $failed failed"
  [[ "$failed" -eq 0 ]]
}

# Function to update all installed Homebrew programs
update_programs() {
  require_brew
  # Create backup before updating
  backup_installed_programs_and_versions
  generate_brewfile

  log_info "Updating Homebrew and all installed programs..."
  log_debug "Running: brew update && brew upgrade"

  if brew update && brew upgrade; then
    log_success "All programs updated successfully"
    notify_completion "Homebrew update completed"
    return 0
  else
    log_error "Failed to update some programs"
    notify_completion "Homebrew update finished with errors"
    return 1
  fi
}

# Reinstall packages listed in the legacy backup (always installs current versions)
reinstall_from_backup() {
  require_brew

  if [[ ! -f "$BACKUP_FILE" ]]; then
    log_error "No backup file found ($BACKUP_FILE). Cannot reinstall packages."
    return 1
  fi

  log_warning "This reinstalls the current package versions; it does not roll them back."
  echo ""
  log_info "Backup file contains $(wc -l < "$BACKUP_FILE" | tr -d ' ') packages"
  read -rp "Continue with reinstall? [y/N]: " -n 1
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Rollback cancelled"
    return 0
  fi

  log_info "Reinstalling packages from backup..."
  local success=0
  local failed=0
  local skipped=0

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    local program version
    program=$(echo "$line" | awk '{print $1}')
    version=$(echo "$line" | awk '{print $2}')

    # Skip if already at latest
    if brew list --formula "$program" &> /dev/null || brew list --cask "$program" &> /dev/null; then
      log_info "Reinstalling $program (was v$version)..."
      if brew reinstall "$program" 2>/dev/null; then
        log_success "$program reinstalled"
        ((success++)) || true
      else
        log_warning "Could not reinstall $program"
        ((failed++)) || true
      fi
    else
      log_warning "$program not currently installed, skipping"
      ((skipped++)) || true
    fi
  done < "$BACKUP_FILE"

  log_info "Summary: $success reinstalled, $skipped skipped, $failed failed"
  return 0
}

# Function to check Homebrew health
check_brew_health() {
  require_brew
  [[ -z "${1:-}" || "$1" == "--fix" ]] || { log_error "Unknown doctor option: $1"; return 1; }
  log_info "Checking Homebrew health..."
  [[ "${1:-}" != "--fix" ]] || log_info "Suggested fixes will be shown but not run automatically."
  # brew doctor returns non-zero for warnings, which is normal
  if brew doctor; then
    log_success "Homebrew is healthy!"
  else
    log_warning "Homebrew reported some issues (see above)"
  fi
  return 0
}

# Function to clean up Homebrew
cleanup_brew() {
  require_brew
  log_info "Checking what can be cleaned up..."

  # Show dry-run first so user knows what will be removed
  local dry_run_output
  dry_run_output=$(brew cleanup -n 2>&1) || true

  if [[ -z "$dry_run_output" ]]; then
    log_success "Nothing to clean up - Homebrew is already tidy!"
    return 0
  fi

  echo "$dry_run_output"
  echo ""
  read -rp "Proceed with cleanup? [y/N]: " -n 1
  echo

  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Cleanup cancelled"
    return 0
  fi

  log_info "Cleaning up Homebrew..."
  if brew cleanup -s; then
    log_success "Homebrew cleaned up successfully"
    return 0
  else
    log_error "Failed to clean up Homebrew"
    return 1
  fi
}

# Function to search for a Homebrew package
search_package() {
  require_brew
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

# Function to show detailed package information
show_package_info() {
  require_brew
  local package="${1:-}"

  if [[ -z "$package" ]]; then
    read -rp "Enter the name of the package: " package
  fi

  if [[ -z "$package" ]]; then
    log_error "No package name provided"
    return 1
  fi

  log_info "Fetching info for '$package'..."

  # Check if it's a formula or cask
  if brew list --formula "$package" &> /dev/null; then
    log_info "$package is installed as a formula"
    brew info "$package"
  elif brew list --cask "$package" &> /dev/null; then
    log_info "$package is installed as a cask"
    brew info --cask "$package"
  else
    # Not installed, try to show info anyway
    log_warning "$package is not installed, showing available info..."
    brew info "$package" 2>/dev/null || brew info --cask "$package" 2>/dev/null || {
      log_error "Package '$package' not found"
      return 1
    }
  fi

  return 0
}

# Function to list outdated Homebrew packages
list_outdated_packages() {
  require_brew
  log_info "Listing all outdated Homebrew packages..."

  local outdated_count
  outdated_count=$(brew outdated | wc -l | tr -d ' ')

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
  require_brew
  log_info "Listing installed casks (GUI applications)..."

  local cask_count
  cask_count=$(brew list --cask | wc -l | tr -d ' ')

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
  require_brew
  log_info "Listing installed formulae (CLI tools)..."

  local formula_count
  formula_count=$(brew list --formula | wc -l | tr -d ' ')

  if [[ "$formula_count" -eq 0 ]]; then
    log_info "No formulae installed"
  else
    brew list --formula
    log_info "Total formulae installed: $formula_count"
  fi

  return 0
}

list_all() {
  list_formulae
  echo ""
  list_casks
}

upgrade_selected() {
  require_brew
  local packages=() item selected reply upgraded=0 failed=0
  while IFS= read -r item; do packages+=("Formula: $item"); done < <(brew outdated --formula)
  while IFS= read -r item; do packages+=("Cask: $item"); done < <(brew outdated --cask)
  ((${#packages[@]})) || { log_success "All packages are up to date!"; return 0; }

  selected=$(pick_items "Upgrade Homebrew packages" "Select one or more packages:" "${packages[@]}") || return 1
  [[ -n "$selected" ]] || { log_info "Upgrade cancelled"; return 0; }
  printf 'Selected:\n%s\n' "$selected"
  read -rp "Upgrade these packages? [y/N]: " reply
  [[ "$reply" =~ ^[Yy]$ ]] || { log_info "Upgrade cancelled"; return 0; }

  while IFS= read -r item; do
    if [[ "$item" == "Cask: "* ]]; then
      if brew upgrade --cask "${item#Cask: }"; then ((upgraded++)) || true; else ((failed++)) || true; fi
    else
      if brew upgrade --formula "${item#Formula: }"; then ((upgraded++)) || true; else ((failed++)) || true; fi
    fi
  done <<< "$selected"
  log_info "Upgrade summary: $upgraded upgraded, $failed failed"
  notify_completion "$upgraded upgraded, $failed failed"
  [[ "$failed" -eq 0 ]]
}

info_selected() {
  require_brew
  local packages=() item selected
  while IFS= read -r item; do packages+=("Formula: $item"); done < <(brew list --formula)
  while IFS= read -r item; do packages+=("Cask: $item"); done < <(brew list --cask)
  ((${#packages[@]})) || { log_info "No Homebrew packages are installed"; return 0; }

  selected=$(pick_items "Homebrew package info" "Select one or more packages:" "${packages[@]}") || return 1
  [[ -n "$selected" ]] || { log_info "No package selected"; return 0; }
  while IFS= read -r item; do
    echo ""
    if [[ "$item" == "Cask: "* ]]; then brew info --cask "${item#Cask: }"; else brew info --formula "${item#Formula: }"; fi
  done <<< "$selected"
}

open_selected() {
  require_brew
  [[ "$OSTYPE" == darwin* ]] || { log_error "Opening GUI applications is available on macOS only"; return 1; }
  local casks=() cask selected app_path opened=0 failed=0
  while IFS= read -r cask; do casks+=("$cask"); done < <(brew list --cask)
  ((${#casks[@]})) || { log_info "No casks are installed"; return 0; }

  selected=$(pick_items "Open applications" "Select one or more applications:" "${casks[@]}") || return 1
  [[ -n "$selected" ]] || { log_info "No application selected"; return 0; }
  while IFS= read -r cask; do
    app_path=$(brew list --cask "$cask" 2>/dev/null | awk '/\.app$/ { print; exit }')
    if [[ -n "$app_path" ]] && open "$app_path"; then ((opened++)) || true; else log_warning "No application found for $cask"; ((failed++)) || true; fi
  done <<< "$selected"
  log_info "Open summary: $opened opened, $failed failed"
  [[ "$failed" -eq 0 ]]
}

# Validate that a package exists in Homebrew before installation
validate_package() {
  local pkg="$1"
  if ! brew info "$pkg" &>/dev/null && ! brew info --cask "$pkg" &>/dev/null; then
    log_error "Package '$pkg' not found in Homebrew"
    return 1
  fi
  return 0
}

# Function to install a cask
install_cask() {
  require_brew
  local cask="${1:-}"

  if [[ -z "$cask" ]]; then
    read -rp "Enter the name of the cask to install: " cask
  fi

  if [[ -z "$cask" ]]; then
    log_error "No cask name provided"
    return 1
  fi

  log_debug "Validating package: $cask"
  if ! validate_package "$cask"; then
    return 1
  fi

  log_info "Installing cask: $cask..."
  log_debug "Running: brew install --cask $cask"

  if brew install --cask "$cask"; then
    log_success "Cask $cask installed successfully"
    notify_completion "$cask installed successfully"
    return 0
  else
    log_error "Failed to install cask $cask"
    notify_completion "$cask installation failed"
    return 1
  fi
}

# Function to show help
show_help() {
  cat << EOF
Simple Brew Tools v${SCRIPT_VERSION} - Modern Homebrew Management

USAGE:
    $(basename "$0") [OPTIONS] [COMMAND] [ARGS]

OPTIONS:
    --verbose, -V                 Enable verbose/debug output

COMMANDS:
    install-homebrew              Install Homebrew if not already installed
    backup                        Backup installed programs (legacy format)
    export [OPTIONS]              Export to Brewfile (--file, --global, --no-describe)
    restore [OPTIONS]             Restore (--file, --no-upgrade, --check-first)
    check                         Show missing Brewfile dependencies
    cleanup-brewfile              Remove dependencies not listed in Brewfile
    migrate [--no-upgrade]        Install Homebrew if needed, then restore
    status                        Show Homebrew and Brewfile status
    files                         List generated files, sizes, and dates
    open                          Open the generated-files folder
    completion bash|zsh           Print shell completion setup
    generate-brewfile             Alias for export
    install-brewfile              Alias for restore
    install-programs              Install programs from $PROGRAMS_LIST_FILE
    uninstall-programs            Uninstall programs from $PROGRAMS_LIST_FILE
    update                        Update all installed programs
    reinstall                     Reinstall current packages from the legacy backup
    health, doctor [--fix]        Check health and show suggested fixes
    cleanup                       Clean up old Homebrew files (with confirmation)
    cleanup-preview               Preview cleanup, then optionally confirm it
    search [PACKAGE]              Search for a package
    info [PACKAGE]                Show detailed package information
    outdated                      List outdated packages
    upgrade-select                Pick outdated packages to upgrade with the mouse (macOS)
    list                          List all installed formulae and casks
    list-casks                    List installed casks (GUI apps)
    list-formulae                 List installed formulae (CLI tools)
    install-cask [CASK]           Install a cask (GUI application)
    info-select                   Pick installed packages and show their details (macOS)
    open-select                   Pick installed GUI applications to open (macOS)
    uninstall-select              Pick packages to uninstall with the mouse (macOS)
    interactive                   Run in interactive menu mode (default)
    help, --help, -h              Show this help message
    version, --version, -v        Show version information

EXAMPLES:
    $(basename "$0")                          # Run in interactive mode
    $(basename "$0") update                   # Update all packages
    $(basename "$0") export                   # Export this computer's Homebrew setup
    $(basename "$0") restore                  # Restore it on another computer
    $(basename "$0") check                    # Check what is missing
    $(basename "$0") migrate                  # Install Homebrew and restore
    $(basename "$0") search wget              # Search for wget
    $(basename "$0") info git                 # Show info about git
    $(basename "$0") install-cask firefox     # Install Firefox
    $(basename "$0") --verbose update         # Update with debug output

FILES:
    .brew-tools.conf            Configuration file (overrides defaults)
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
  echo " 8.  Reinstall current packages from legacy backup"
  echo " 9.  Check Homebrew health"
  echo " 10. Clean up Homebrew"
  echo " 11. Search for a package"
  echo " 12. Show package info"
  echo " 13. List outdated packages"
  echo " 14. List installed casks (GUI apps)"
  echo " 15. List installed formulae (CLI tools)"
  echo " 16. Install a cask (GUI app)"
  echo " 17. Show generated files"
  echo " 18. Open generated-files folder"
  echo " 19. Select packages to uninstall (macOS)"
  echo " 20. Select outdated packages to upgrade (macOS)"
  echo " 21. Select packages and show info (macOS)"
  echo " 22. Select GUI applications to open (macOS)"
  echo " 0.  Exit"
  echo ""
  read -rp "Enter your choice [0-22]: " choice

  case $choice in
    1)  install_homebrew ;;
    2)  backup_installed_programs_and_versions ;;
    3)  generate_brewfile ;;
    4)  install_from_brewfile ;;
    5)  install_programs ;;
    6)  uninstall_programs ;;
    7)  update_programs ;;
    8)  reinstall_from_backup ;;
    9)  check_brew_health ;;
    10) cleanup_brew ;;
    11) search_package ;;
    12) show_package_info ;;
    13) list_outdated_packages ;;
    14) list_casks ;;
    15) list_formulae ;;
    16) install_cask ;;
    17) show_generated_files ;;
    18) open_folder "$(absolute_path "$BREWFILE")" ;;
    19) uninstall_selected ;;
    20) upgrade_selected ;;
    21) info_selected ;;
    22) open_selected ;;
    0)  log_info "Exiting..."; exit 0 ;;
    *)  log_error "Invalid choice. Please select 0-22."; return 1 ;;
  esac
}

# Main function
main() {
  # Parse global flags before commands
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --verbose|-V)
        VERBOSE=true
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  # Load config file (may override defaults including VERBOSE)
  load_config

  # Initialize brew path if installed
  init_brew_path

  log_debug "brew-tools v${SCRIPT_VERSION} starting (verbose mode enabled)"

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
      export|generate-brewfile)
        generate_brewfile "${@:2}"
        ;;
      restore|install-brewfile)
        install_from_brewfile "${@:2}"
        ;;
      check)
        check_brewfile "${2:-}"
        ;;
      cleanup-brewfile)
        cleanup_brewfile "${2:-}"
        ;;
      migrate)
        migrate "${@:2}"
        ;;
      status)
        show_status
        ;;
      files)
        show_generated_files
        ;;
      open)
        open_folder "$(absolute_path "$BREWFILE")"
        ;;
      completion)
        show_completion "${2:-}"
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
      reinstall)
        reinstall_from_backup
        ;;
      health|doctor)
        check_brew_health "${2:-}"
        ;;
      cleanup|cleanup-preview)
        cleanup_brew
        ;;
      search)
        search_package "${2:-}"
        ;;
      info)
        show_package_info "${2:-}"
        ;;
      outdated)
        list_outdated_packages
        ;;
      upgrade-select)
        upgrade_selected
        ;;
      list)
        list_all
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
      info-select)
        info_selected
        ;;
      open-select)
        open_selected
        ;;
      uninstall-select)
        uninstall_selected
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
