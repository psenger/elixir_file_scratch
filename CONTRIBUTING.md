# Contributing to Elixir File Scratch

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## Code of Conduct

Please be respectful and constructive in all interactions. We welcome contributors of all experience levels.

## How to Contribute

### Reporting Bugs

1. Check existing [issues](https://github.com/psenger/elixir_file_scratch/issues) to avoid duplicates
2. Use the bug report template when creating a new issue
3. Include as much detail as possible:
   - Elixir and OTP versions (`elixir --version`)
   - Operating system
   - Steps to reproduce
   - Expected vs actual behavior

### Suggesting Features

1. Check existing issues for similar suggestions
2. Use the feature request template
3. Explain the use case and why it would benefit the project

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Make your changes
4. Ensure all tests pass:
   ```bash
   mix test
   ```
5. Ensure code is formatted:
   ```bash
   mix format
   ```
6. Commit with a clear message describing the change
7. Push to your fork and open a pull request

## Development Setup

### Prerequisites

- Elixir ~> 1.19
- Erlang/OTP (compatible version)

### Getting Started

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/elixir_file_scratch.git
cd elixir_file_scratch

# Install dependencies
mix deps.get

# Run tests
mix test

# Build the escript
mix escript.build
```

## Code Style

- Follow standard Elixir conventions
- Use `mix format` before committing
- Add `@doc` and `@spec` for public functions
- Write descriptive commit messages

## Testing

This project maintains comprehensive test coverage. When contributing, please follow these testing guidelines:

### Running Tests

```bash
# Run all tests
mix test

# Run with verbose output
mix test --trace

# Run a specific test file
mix test test/elixir_file_scratch_test.exs

# Run a specific test by line number
mix test test/elixir_file_scratch_test.exs:42
```

### Test Requirements

- Add tests for all new functionality
- Ensure existing tests pass before submitting a PR
- Use descriptive test names that explain what is being tested
- Group related tests using `describe` blocks
- Use the `setup` callback for common test fixtures

### Test Structure

Tests are organized into logical groups:
- **Help flags** - CLI argument parsing
- **read_all/2** - Slurp file reading
- **read_line_by_line/2** - Stream file reading
- **Error handling** - Error cases and edge conditions
- **Integration** - Cross-function behavior
- **Edge cases** - Unicode, special characters, empty files

## Questions?

Feel free to open an issue for any questions about contributing.
