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

@test "Script exists and is executable" {
  [ -f "$BREW_TOOLS" ]
  [ -x "$BREW_TOOLS" ]
}

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

@test "Script uses proper shebang" {
  run head -n 1 "$BREW_TOOLS"
  [[ "$output" =~ "#!/usr/bin/env bash" ]]
}

# Test that the script can be sourced without errors (syntax check)
@test "Script has valid bash syntax" {
  run bash -n "$BREW_TOOLS"
  [ "$status" -eq 0 ]
}

# Test for ShellCheck compliance (if shellcheck is installed)
@test "Script passes ShellCheck (if available)" {
  if command -v shellcheck &> /dev/null; then
    run shellcheck "$BREW_TOOLS"
    [ "$status" -eq 0 ]
  else
    skip "shellcheck not installed"
  fi
}
