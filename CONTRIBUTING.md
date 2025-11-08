# Contributing to Simple Brew Tools

Thank you for your interest in contributing to Simple Brew Tools! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:

1. **Clear title**: Describe the bug briefly
2. **Description**: Detailed description of the issue
3. **Steps to reproduce**: Step-by-step instructions
4. **Expected behavior**: What should happen
5. **Actual behavior**: What actually happens
6. **Environment**:
   - OS and version (macOS 14.0, Ubuntu 22.04, etc.)
   - Bash version (`bash --version`)
   - Homebrew version (`brew --version`)
   - Script version (`./brew-tools.sh --version`)
7. **Error messages**: Include any relevant error output
8. **Screenshots**: If applicable

### Suggesting Features

Feature requests are welcome! Please create an issue with:

1. **Clear title**: Describe the feature briefly
2. **Use case**: Explain why this feature would be useful
3. **Proposed solution**: If you have ideas on implementation
4. **Alternatives**: Any alternative solutions you've considered

### Pull Requests

We love pull requests! Here's the process:

1. **Fork the repository**
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/my-amazing-feature
   ```
3. **Make your changes**
4. **Test your changes** (see Testing section below)
5. **Run code quality checks** (see Code Quality section below)
6. **Commit with a clear message**:
   ```bash
   git commit -m "Add feature: description of feature"
   ```
7. **Push to your fork**:
   ```bash
   git push origin feature/my-amazing-feature
   ```
8. **Create a Pull Request** with:
   - Clear description of changes
   - Link to related issue (if applicable)
   - Screenshots/examples (if applicable)

## Development Setup

### Prerequisites

- Bash 4.0 or newer
- Git
- Homebrew (for testing on macOS/Linux)
- bats-core (for running tests)
- ShellCheck (for code quality)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/simple-brew-tools.git
cd simple-brew-tools

# Make script executable
chmod +x brew-tools.sh

# Install development dependencies
# macOS
brew install bats-core shellcheck

# Ubuntu/Debian
sudo apt-get install bats shellcheck
```

## Testing

### Running Tests

Run all tests:

```bash
bats tests/test_brew_tools.bats
```

Run tests with verbose output:

```bash
bats -t tests/test_brew_tools.bats
```

Run tests in all .bats files:

```bash
bats tests/
```

### Writing Tests

Tests use bats-core syntax. Example:

```bash
@test "Description of what you're testing" {
  run ./brew-tools.sh --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "expected text" ]]
}
```

Test files should:
- Be placed in `tests/` directory
- Use `.bats` extension
- Include setup/teardown functions if needed
- Test both success and failure cases
- Be independent (not rely on other tests)

### Manual Testing

Before submitting a PR, test:

1. **Interactive mode**: Run `./brew-tools.sh` and try each menu option
2. **CLI mode**: Test all commands with arguments
3. **Error handling**: Test with invalid inputs
4. **Different platforms**: Test on macOS and Linux if possible

## Code Quality

### ShellCheck

Run ShellCheck before committing:

```bash
shellcheck brew-tools.sh
```

The script should pass with no warnings or errors.

### Shell Script Best Practices

Follow these guidelines:

1. **Use `set -euo pipefail`**: Already set in the script
2. **Use `[[ ]]` instead of `[ ]`**: For conditionals
3. **Quote variables**: Always quote: `"$variable"`
4. **Use local variables**: In functions: `local var="value"`
5. **Use readonly for constants**: `readonly CONSTANT="value"`
6. **Return proper exit codes**: 0 for success, 1+ for errors
7. **Use functions**: Break code into logical functions
8. **Add comments**: Explain complex logic
9. **Error handling**: Check command success, provide helpful errors
10. **Avoid eval**: Don't use `eval` with untrusted input

### Code Style

- **Indentation**: 2 spaces (no tabs)
- **Line length**: Prefer under 100 characters
- **Function names**: Use snake_case: `function_name()`
- **Variable names**: Use lowercase with underscores: `my_variable`
- **Constants**: Use uppercase: `MY_CONSTANT`
- **Comments**: Use `#` for single-line comments

### Commit Messages

Follow conventional commits format:

```
type(scope): subject

body

footer
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test changes
- `refactor`: Code refactoring
- `style`: Code style changes (formatting)
- `chore`: Build process or auxiliary tool changes
- `ci`: CI/CD changes

Examples:
```
feat(cask): add support for cask installation

Add install-cask command to install GUI applications.
Includes both interactive and CLI modes.

Closes #123
```

```
fix(backup): handle missing backup file gracefully

Previously the script would exit with error.
Now it shows a helpful message and continues.
```

## Project Structure

```
simple-brew-tools/
├── brew-tools.sh              # Main script - ALL code goes here
├── README.md                  # User documentation
├── CONTRIBUTING.md           # This file
├── CHANGELOG.md              # Version history
├── LICENSE                    # MIT license
├── .gitignore                # Git ignore rules
├── .markdownlint.json        # Markdown linting config
├── tests/
│   ├── README.md            # Test documentation
│   └── test_brew_tools.bats # Test suite
└── .github/
    └── workflows/
        └── ci.yml           # GitHub Actions CI/CD
```

## CI/CD

All pull requests automatically run:

1. **ShellCheck**: Validates shell script quality
2. **Tests**: Runs on Ubuntu and macOS
3. **Structure validation**: Checks required files exist
4. **Markdown linting**: Validates documentation

PRs must pass all checks before merging.

## Release Process

Maintainers follow this process for releases:

1. Update version in `brew-tools.sh` (SCRIPT_VERSION)
2. Update `CHANGELOG.md` with release notes
3. Create a git tag: `git tag -a v2.0.0 -m "Release v2.0.0"`
4. Push tag: `git push origin v2.0.0`
5. Create GitHub release from tag with changelog

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Bugs**: Open a GitHub Issue
- **Chat**: (Add chat platform if available)

## Recognition

Contributors will be recognized in:
- GitHub contributors list
- Release notes
- README acknowledgments (for significant contributions)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Thank You!

Your contributions make Simple Brew Tools better for everyone. We appreciate your time and effort!
