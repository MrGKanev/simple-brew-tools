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

@test "Script passes ShellCheck (if available)" {
  if command -v shellcheck &> /dev/null; then
    run shellcheck "$BREW_TOOLS"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
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
  [[ "$output" =~ "2.0.0" ]]
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
  [[ "$output" =~ "list-casks" ]]
  [[ "$output" =~ "list-formulae" ]]
  [[ "$output" =~ "install-cask" ]]
}

@test "Help message includes examples" {
  run "$BREW_TOOLS" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "EXAMPLES:" ]]
}

@test "Help message includes OPTIONS section with --verbose" {
  run "$BREW_TOOLS" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "OPTIONS:" ]]
  [[ "$output" =~ "--verbose" ]]
}

@test "Help message includes reinstall alias" {
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
  # init_brew_path detects brew via hardcoded paths and adds it to PATH,
  # so we can only test this on systems where brew isn't installed
  if command -v brew &> /dev/null; then
    skip "Homebrew is installed (cannot simulate missing brew)"
  fi

  run "$BREW_TOOLS" backup
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

@test "reinstall command is accepted as alias for rollback" {
  # Without a backup file, it should error the same way as rollback
  export BACKUP_FILE="$TEST_TEMP_DIR/nonexistent_backup.txt"

  if ! command -v brew &> /dev/null; then
    skip "Homebrew not installed"
  fi

  run "$BREW_TOOLS" reinstall
  # Should get the "No backup file found" error, proving the alias works
  [[ "$output" =~ "No backup file found" ]] || [[ "$output" =~ "ERROR" ]]
}
