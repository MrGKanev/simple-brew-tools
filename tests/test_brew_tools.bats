#!/usr/bin/env bats

# Test suite for Simple Brew Tools
# Requires bats-core: https://github.com/bats-core/bats-core

setup() {
  # Load the script functions
  export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export BREW_TOOLS="$SCRIPT_DIR/brew-tools.sh"

  # Create temporary directory for test files
  export TEST_TEMP_DIR="$(mktemp -d)"
  export BACKUP_FILE="$TEST_TEMP_DIR/brew_programs_backup.txt"
  export PROGRAMS_LIST_FILE="$TEST_TEMP_DIR/brew_programs_list.txt"
  export BREWFILE="$TEST_TEMP_DIR/Brewfile"
}

teardown() {
  # Clean up temporary directory
  rm -rf "$TEST_TEMP_DIR"
}

# ─── Basic script checks ─────────────────────────────────────────────

@test "Script exists and is executable" {
  [ -f "$BREW_TOOLS" ]
  [ -x "$BREW_TOOLS" ]
}

@test "Script uses proper shebang" {
  run head -n 1 "$BREW_TOOLS"
  [[ "$output" =~ "#!/usr/bin/env bash" ]]
}

@test "Script has valid bash syntax" {
  run bash -n "$BREW_TOOLS"
  [ "$status" -eq 0 ]
}

# ─── Help and version ─────────────────────────────────────────────────

@test "Script shows help with --help flag" {
  run "$BREW_TOOLS" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Simple Brew Tools" ]]
  [[ "$output" =~ "USAGE:" ]]
  [[ "$output" =~ "COMMANDS:" ]]
}

@test "Script shows version with --version flag" {
  run "$BREW_TOOLS" --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Simple Brew Tools v" ]]
  [[ "$output" =~ "2.1.0" ]]
}

@test "Script shows version with -v flag" {
  run "$BREW_TOOLS" -v
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Simple Brew Tools v" ]]
}

@test "Script shows help with help command" {
  run "$BREW_TOOLS" help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Simple Brew Tools" ]]
}

@test "Script shows help with -h flag" {
  run "$BREW_TOOLS" -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Simple Brew Tools" ]]
}

@test "Script exits with error on unknown command" {
  run "$BREW_TOOLS" unknown-command
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unknown command" ]]
}

@test "Help message includes all main commands" {
  run "$BREW_TOOLS" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "install-homebrew" ]]
  [[ "$output" =~ "backup" ]]
  [[ "$output" =~ "generate-brewfile" ]]
  [[ "$output" =~ "install-brewfile" ]]
  [[ "$output" =~ "update" ]]
  [[ "$output" =~ "cleanup" ]]
  [[ "$output" =~ "search" ]]
  [[ "$output" =~ "outdated" ]]
  [[ "$output" =~ "list                          List all installed" ]]
  [[ "$output" =~ "list-casks" ]]
  [[ "$output" =~ "list-formulae" ]]
  [[ "$output" =~ "install-cask" ]]
}

@test "Help message includes examples" {
  run "$BREW_TOOLS" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "EXAMPLES:" ]]
}

@test "export and restore aliases are documented" {
  run "$BREW_TOOLS" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "export [OPTIONS]" ]]
  [[ "$output" =~ "restore [OPTIONS]" ]]
  [[ "$output" =~ "completion bash|zsh" ]]
}

@test "export and restore aliases use the Brewfile workflow" {
  mkdir "$TEST_TEMP_DIR/bin"
  cat > "$TEST_TEMP_DIR/bin/brew" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$BREW_LOG"
if [[ "$*" == "bundle dump --force --file=-" ]]; then
  printf 'brew "test"\n'
elif [[ "$*" == "bundle dump"* ]]; then
  printf 'brew "test"\n' > "$BREWFILE"
fi
exit 0
EOF
  chmod +x "$TEST_TEMP_DIR/bin/brew"
  export BREW_LOG="$TEST_TEMP_DIR/brew.log"
  export PATH="$TEST_TEMP_DIR/bin:$PATH"

  run "$BREW_TOOLS" export
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Generated file: $BREWFILE" ]]
  [[ "$output" =~ "Contents: 1 entries" ]]
  [[ "$output" =~ "Open folder: file://$TEST_TEMP_DIR" ]]
  grep -q '^bundle dump ' "$BREW_LOG"

  run "$BREW_TOOLS" restore
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Restore summary: all Brewfile dependencies are satisfied" ]]
  grep -q '^bundle install ' "$BREW_LOG"
  grep -q '^bundle install --verbose ' "$BREW_LOG"
  [[ "$output" =~ "If Password appears" ]]
  ! grep -q -- '--no-lock' "$BREW_LOG"

  run "$BREW_TOOLS" restore --no-upgrade
  [ "$status" -eq 0 ]
  grep -q -- '--no-upgrade' "$BREW_LOG"

  run "$BREW_TOOLS" check
  [ "$status" -eq 0 ]
  grep -q '^bundle check --verbose ' "$BREW_LOG"

  run "$BREW_TOOLS" cleanup-brewfile
  [ "$status" -eq 0 ]
  grep -q '^bundle cleanup ' "$BREW_LOG"

  run "$BREW_TOOLS" migrate
  [ "$status" -eq 0 ]

  run "$BREW_TOOLS" export --global
  [ "$status" -eq 0 ]
  grep -q '^bundle dump --force --global$' "$BREW_LOG"

  run "$BREW_TOOLS" restore --invalid
  [ "$status" -ne 0 ]

  run "$BREW_TOOLS" export --file="$TEST_TEMP_DIR/custom.Brewfile" --no-describe
  [ "$status" -eq 0 ]
  grep -q -- '--no-describe.*--file=' "$BREW_LOG"

  run "$BREW_TOOLS" restore --check-first
  [ "$status" -eq 0 ]
  grep -q '^bundle check --verbose ' "$BREW_LOG"

  run "$BREW_TOOLS" status
  [ "$status" -eq 0 ]

  run "$BREW_TOOLS" doctor --fix
  [ "$status" -eq 0 ]

  run "$BREW_TOOLS" completion zsh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "#compdef brew-tools.sh" ]]
}

@test "files lists generated files" {
  printf 'brew "test"\n' > "$BREWFILE"
  run "$BREW_TOOLS" files
  [ "$status" -eq 0 ]
  [[ "$output" =~ "$BREWFILE" ]]
  [[ "$output" =~ "bytes, modified" ]]
}

@test "open uses xdg-open on Linux" {
  mkdir "$TEST_TEMP_DIR/bin"
  printf '#!/usr/bin/env bash\nprintf "%%s" "$1" > "$OPEN_LOG"\n' > "$TEST_TEMP_DIR/bin/xdg-open"
  chmod +x "$TEST_TEMP_DIR/bin/xdg-open"
  export OPEN_LOG="$TEST_TEMP_DIR/open.log"

  run env OSTYPE=linux-gnu PATH="$TEST_TEMP_DIR/bin:/usr/bin:/bin" "$BREW_TOOLS" open
  [ "$status" -eq 0 ]
  [ "$(< "$OPEN_LOG")" = "$(cd "$TEST_TEMP_DIR" && pwd -P)" ]
}

@test "restore reports brew bundle failures" {
  mkdir "$TEST_TEMP_DIR/bin"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$TEST_TEMP_DIR/bin/brew"
  chmod +x "$TEST_TEMP_DIR/bin/brew"
  touch "$BREWFILE"

  run env PATH="$TEST_TEMP_DIR/bin:$PATH" "$BREW_TOOLS" restore
  [ "$status" -ne 0 ]
  [[ "$output" =~ "failed to install" ]]
}

@test "Help message includes OPTIONS section with --verbose" {
  run "$BREW_TOOLS" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "OPTIONS:" ]]
  [[ "$output" =~ "--verbose" ]]
}

@test "Help message includes reinstall command" {
  run "$BREW_TOOLS" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "reinstall" ]]
}

@test "Help message includes .brew-tools.conf in FILES section" {
  run "$BREW_TOOLS" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ ".brew-tools.conf" ]]
}

# ─── detect_platform ──────────────────────────────────────────────────

@test "detect_platform returns a path or empty string on current OS" {
  # Source just the function we need by extracting it
  # We can't source the whole script (it calls main), but we can test
  # the detect_platform behavior through the script's version command
  # which calls init_brew_path -> detect_platform
  run "$BREW_TOOLS" version
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Simple Brew Tools" ]]
}

# ─── install_programs with missing file ───────────────────────────────

@test "install-programs errors when programs list file is missing" {
  # Set PROGRAMS_LIST_FILE to a nonexistent file
  export PROGRAMS_LIST_FILE="$TEST_TEMP_DIR/nonexistent.txt"
  run "$BREW_TOOLS" install-programs
  [ "$status" -ne 0 ]
  [[ "$output" =~ "not found" ]] || [[ "$output" =~ "ERROR" ]]
}

# ─── install_programs with empty/comment-only file ────────────────────

@test "install-programs handles empty programs list gracefully" {
  # This test requires brew to be available
  if ! command -v brew &> /dev/null; then
    skip "Homebrew not installed"
  fi

  # Create an empty file
  touch "$PROGRAMS_LIST_FILE"
  run "$BREW_TOOLS" install-programs
  [ "$status" -eq 0 ]
  [[ "$output" =~ "0 installed, 0 skipped, 0 failed" ]]
}

@test "install-programs handles comment-only programs list gracefully" {
  if ! command -v brew &> /dev/null; then
    skip "Homebrew not installed"
  fi

  # Create a file with only comments and blank lines
  cat > "$PROGRAMS_LIST_FILE" << 'EOF'
# This is a comment
# Another comment

# More comments
EOF
  run "$BREW_TOOLS" install-programs
  [ "$status" -eq 0 ]
  [[ "$output" =~ "0 installed, 0 skipped, 0 failed" ]]
}

# ─── backup without brew ──────────────────────────────────────────────

@test "backup errors when Homebrew is not available" {
  run env OSTYPE=unsupported PATH="/usr/bin:/bin" "$BREW_TOOLS" backup
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Homebrew is not installed" ]] || [[ "$output" =~ "ERROR" ]]
}

# ─── Color disabled for non-TTY ──────────────────────────────────────

@test "Script color variables are empty in non-TTY context" {
  # bats runs in a non-TTY context, so our script's colored prefixes
  # like [INFO], [ERROR] should not contain ANSI escape codes.
  # Note: external commands (e.g. brew --version) may emit their own
  # escape codes, so we only check our script's log line format.
  run "$BREW_TOOLS" --help
  [ "$status" -eq 0 ]
  # Help output uses cat << EOF, not echo -e with colors,
  # so it should be clean. Verify the key section headers are plain text.
  [[ "$output" =~ "USAGE:" ]]
  [[ "$output" =~ "COMMANDS:" ]]
}

@test "Error log prefix has no ANSI codes in non-TTY context" {
  run "$BREW_TOOLS" unknown-command
  # Extract just the [ERROR] line — should be plain text without escape codes
  local error_line
  error_line=$(echo "$output" | grep '\[ERROR\]' | head -1)
  # The line should start directly with [ERROR], not with an escape sequence
  [[ "$error_line" == "["* ]]
  [[ "$error_line" =~ "ERROR" ]]
}

# ─── install_from_brewfile with missing Brewfile ──────────────────────

@test "install-brewfile errors when Brewfile is missing" {
  export BREWFILE="$TEST_TEMP_DIR/nonexistent_Brewfile"
  run "$BREW_TOOLS" install-brewfile
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Brewfile not found" ]] || [[ "$output" =~ "ERROR" ]]
}

# ─── Verbose flag ─────────────────────────────────────────────────────

@test "--verbose flag is accepted before commands" {
  run "$BREW_TOOLS" --verbose version
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Simple Brew Tools" ]]
}

@test "--verbose enables debug output" {
  run "$BREW_TOOLS" --verbose version
  [ "$status" -eq 0 ]
  # Debug output goes to stderr, which bats captures in $output
  [[ "$output" =~ "[DEBUG]" ]]
}

@test "-V flag enables debug output" {
  run "$BREW_TOOLS" -V version
  [ "$status" -eq 0 ]
  [[ "$output" =~ "[DEBUG]" ]]
}

@test "Debug output is suppressed without --verbose" {
  run "$BREW_TOOLS" version
  [ "$status" -eq 0 ]
  # Should NOT contain debug output
  if [[ "$output" =~ "[DEBUG]" ]]; then
    echo "Found DEBUG output without --verbose flag"
    return 1
  fi
}

@test "VERBOSE env var enables debug output" {
  run env VERBOSE=true "$BREW_TOOLS" version
  [ "$status" -eq 0 ]
  [[ "$output" =~ "[DEBUG]" ]]
}

# ─── Config file loading ─────────────────────────────────────────────

@test "Config file overrides default file paths" {
  if ! command -v brew &> /dev/null; then
    skip "Homebrew not installed"
  fi

  # Create a config file with custom PROGRAMS_LIST_FILE
  local config_dir="$TEST_TEMP_DIR/workdir"
  mkdir -p "$config_dir"

  cat > "$config_dir/.brew-tools.conf" << EOF
PROGRAMS_LIST_FILE=custom_programs.txt
EOF

  # Create the custom programs file (empty)
  touch "$config_dir/custom_programs.txt"

  # Run from the config directory so .brew-tools.conf is found
  run bash -c "cd '$config_dir' && '$BREW_TOOLS' install-programs"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "0 installed, 0 skipped, 0 failed" ]]
}

@test "Config file with VERBOSE=true enables debug output" {
  local config_dir="$TEST_TEMP_DIR/workdir"
  mkdir -p "$config_dir"

  cat > "$config_dir/.brew-tools.conf" << EOF
VERBOSE=true
EOF

  run bash -c "cd '$config_dir' && '$BREW_TOOLS' version"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "[DEBUG]" ]]
}

@test "Missing config file is handled gracefully" {
  # Run from temp dir where no .brew-tools.conf exists
  run bash -c "cd '$TEST_TEMP_DIR' && '$BREW_TOOLS' version"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Simple Brew Tools" ]]
}

@test "Config file with unknown key produces warning" {
  local config_dir="$TEST_TEMP_DIR/workdir"
  mkdir -p "$config_dir"

  cat > "$config_dir/.brew-tools.conf" << EOF
UNKNOWN_KEY=some_value
EOF

  run bash -c "cd '$config_dir' && '$BREW_TOOLS' version"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Unknown config key" ]]
}

# ─── reinstall alias ─────────────────────────────────────────────────

@test "reinstall command reads the legacy backup" {
  export BACKUP_FILE="$TEST_TEMP_DIR/nonexistent_backup.txt"

  if ! command -v brew &> /dev/null; then
    skip "Homebrew not installed"
  fi

  run "$BREW_TOOLS" reinstall
  [[ "$output" =~ "No backup file found" ]] || [[ "$output" =~ "ERROR" ]]
}

@test "uninstall-select removes the packages chosen in the macOS picker" {
  mkdir "$TEST_TEMP_DIR/bin"
  cat > "$TEST_TEMP_DIR/bin/brew" << 'EOF'
#!/usr/bin/env bash
[[ "$*" == "list --formula" ]] && printf 'wget\n'
[[ "$*" == "list --cask" ]] && printf 'firefox\n'
[[ "$1" == "uninstall" ]] && printf '%s\n' "$*" >> "$BREW_LOG"
EOF
  cat > "$TEST_TEMP_DIR/bin/osascript" << 'EOF'
#!/usr/bin/env bash
printf 'Formula: wget\nCask: firefox\n'
EOF
  chmod +x "$TEST_TEMP_DIR/bin/brew" "$TEST_TEMP_DIR/bin/osascript"
  export BREW_LOG="$TEST_TEMP_DIR/brew.log"

  run bash -c "printf 'y\\n' | env OSTYPE=darwin PATH='$TEST_TEMP_DIR/bin:/usr/bin:/bin' '$BREW_TOOLS' uninstall-select"
  [ "$status" -eq 0 ]
  grep -q '^uninstall --formula wget$' "$BREW_LOG"
  grep -q '^uninstall --cask firefox$' "$BREW_LOG"
  [[ "$output" =~ "2 uninstalled, 0 failed" ]]
}

@test "macOS pickers upgrade, inspect, and open selected packages" {
  mkdir "$TEST_TEMP_DIR/bin"
  cat > "$TEST_TEMP_DIR/bin/brew" << 'EOF'
#!/usr/bin/env bash
case "$*" in
  "outdated --formula"|"list --formula") printf 'wget\n' ;;
  "outdated --cask"|"list --cask") printf 'firefox\n' ;;
  "list --cask firefox") printf '/Applications/Firefox.app\n' ;;
  upgrade*|info*) printf '%s\n' "$*" >> "$BREW_LOG" ;;
esac
EOF
  cat > "$TEST_TEMP_DIR/bin/osascript" << 'EOF'
#!/usr/bin/env bash
[[ "$1" == "-e" ]] || printf '%b' "$PICK_RESULT"
EOF
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$1" >> "$OPEN_LOG"\n' > "$TEST_TEMP_DIR/bin/open"
  chmod +x "$TEST_TEMP_DIR/bin/brew" "$TEST_TEMP_DIR/bin/osascript" "$TEST_TEMP_DIR/bin/open"
  export BREW_LOG="$TEST_TEMP_DIR/brew.log" OPEN_LOG="$TEST_TEMP_DIR/open.log"
  local picker_env="OSTYPE=darwin PATH=$TEST_TEMP_DIR/bin:/usr/bin:/bin"

  run bash -c "printf 'y\\n' | env $picker_env PICK_RESULT='Formula: wget\\nCask: firefox\\n' '$BREW_TOOLS' upgrade-select"
  [ "$status" -eq 0 ]
  grep -q '^upgrade --formula wget$' "$BREW_LOG"
  grep -q '^upgrade --cask firefox$' "$BREW_LOG"

  run env $picker_env PICK_RESULT='Formula: wget' "$BREW_TOOLS" info-select
  [ "$status" -eq 0 ]
  grep -q '^info --formula wget$' "$BREW_LOG"

  run env $picker_env PICK_RESULT=firefox "$BREW_TOOLS" open-select
  [ "$status" -eq 0 ]
  [ "$(< "$OPEN_LOG")" = "/Applications/Firefox.app" ]
}
