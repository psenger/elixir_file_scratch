# Elixir File Scratch

[![Elixir](https://img.shields.io/badge/Elixir-~%3E%201.19-purple.svg)](https://elixir-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A skeleton Elixir escript application demonstrating two approaches to file processing from the command line:

1. **Slurping** - Reading the entire file into memory at once
2. **Streaming** - Processing the file line-by-line in a memory-efficient manner

This project serves as both a practical CLI tool and an educational resource for learning idiomatic Elixir patterns.

## Features

- **Two File Reading Strategies**
  - `read_all/2` - Slurp approach for small files
  - `read_line_by_line/2` - Stream approach for large files
- **Higher-Order Functions** - Pass custom processor functions for flexible file handling
- **Proper Error Handling** - Returns `{:ok, result}` or `{:error, reason}` tuples
- **Type Specifications** - Full `@spec` and `@type` annotations
- **CLI Interface** - Built as an escript executable
- **Comprehensive Documentation** - Includes detailed guides on streaming

## Requirements

- Elixir ~> 1.19
- Erlang/OTP (compatible version)

## Installation

### Clone the Repository

```bash
git clone https://github.com/psenger/elixir_file_scratch.git
cd elixir_file_scratch
```

### Install Dependencies

```bash
mix deps.get
```

### Build the Escript

```bash
mix escript.build
```

## Usage

### Command Line

```bash
# Show help
./elixir_file_scratch --help
./elixir_file_scratch -h

# Process a file
./elixir_file_scratch --file /path/to/your/file.txt
./elixir_file_scratch -f /path/to/your/file.txt
```

### As a Library (IEx)

```elixir
# Start interactive Elixir
iex -S mix

# Slurp approach - read entire file into memory
ElixirFileScratch.read_all("/tmp/example.txt", &IO.puts/1)

# Streaming approach - process line by line
ElixirFileScratch.read_line_by_line("/tmp/example.txt", &IO.puts/1)

# Custom processor function
ElixirFileScratch.read_line_by_line("/tmp/data.txt", fn line ->
  String.upcase(line) |> IO.puts()
end)
```

## API Reference

### `read_all(filename, processor)`

Reads the entire file into memory and passes the contents to the processor function.

**Best for:** Small files where you need the complete contents at once.

```elixir
@spec read_all(String.t(), processor()) :: result()
```

### `read_line_by_line(filename, processor)`

Streams the file line-by-line, passing each trimmed line to the processor function.

**Best for:** Large files, log processing, or when memory efficiency matters.

```elixir
@spec read_line_by_line(String.t(), processor()) :: result()
```

## Project Structure

```
elixir_file_scratch/
├── lib/
│   └── elixir_file_scratch.ex    # Main module with all functionality
├── test/
│   ├── elixir_file_scratch_test.exs
│   └── test_helper.exs
├── mix.exs                        # Project configuration
├── STREAMING.md                   # Guide to Elixir Streams
├── CONTRIBUTING.md                # Contribution guidelines
├── LICENSE                        # MIT License
└── README.md                      # This file
```

## Development

### Running Tests

```bash
# Run all tests
mix test

# Run with verbose output
mix test --trace

# Run a specific test file
mix test test/elixir_file_scratch_test.exs

# Run a specific test by line number
mix test test/elixir_file_scratch_test.exs:7
```

### Code Formatting

```bash
# Format all code
mix format

# Check formatting without changes
mix format --check-formatted
```

### Compilation

```bash
mix compile
```

## Design Patterns

This project demonstrates several Elixir best practices:

- **Functional Core, Imperative Shell** - Pure functions return tuples; side effects happen at the edges
- **Higher-Order Functions** - Processor callbacks allow flexible file handling
- **Pattern Matching** - Multiple function clauses for clean control flow
- **Type Specifications** - `@spec` and `@type` for documentation and static analysis
- **Proper Error Handling** - Consistent `{:ok, _}` / `{:error, _}` return values

## Learning Resources

- [STREAMING.md](STREAMING.md) - A deep dive into Elixir's Stream module, covering lazy evaluation, Stream vs Enum comparisons, and practical examples for memory-efficient data processing.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Philip A Senger

---

Made with Elixir
