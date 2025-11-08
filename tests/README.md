# Tests for Simple Brew Tools

This directory contains automated tests for the Simple Brew Tools script using [bats-core](https://github.com/bats-core/bats-core).

## Prerequisites

Install bats-core:

### macOS
```bash
brew install bats-core
```

### Linux
```bash
# Ubuntu/Debian
sudo apt-get install bats

# Or install from source
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Running Tests

Run all tests:
```bash
bats tests/test_brew_tools.bats
```

Run tests with verbose output:
```bash
bats -t tests/test_brew_tools.bats
```

Run all tests in the tests directory:
```bash
bats tests/
```

## Test Coverage

Current tests cover:
- Script existence and executability
- Help and version flags
- Command-line argument parsing
- Error handling for unknown commands
- Bash syntax validation
- ShellCheck compliance (if available)

## Adding New Tests

To add new tests, edit `test_brew_tools.bats` or create a new `.bats` file in this directory.

Example test structure:
```bash
@test "Description of what you're testing" {
  run command_to_test
  [ "$status" -eq 0 ]
  [[ "$output" =~ "expected output" ]]
}
```

## CI/CD Integration

These tests are automatically run by GitHub Actions on every push and pull request. See `.github/workflows/ci.yml` for details.
