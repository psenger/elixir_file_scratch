defmodule ElixirFileScratch do
  @moduledoc """
  A command-line tool for reading and processing text files.

  This module demonstrates idiomatic Elixir patterns including:
  - Escript entry points with proper exit code handling
  - The `with` construct for clean error handling
  - Higher-order functions for flexible text processing
  - Consistent `{:ok, result}` / `{:error, reason}` return conventions

  ## Usage

      elixir_file_scratch --file <filename>
      elixir_file_scratch --help

  ## Architecture

  This module follows the "functional core, imperative shell" pattern:
  - Business logic returns tagged tuples (`{:ok, _}` or `{:error, _}`)
  - Side effects (IO, exit codes) happen only at the edges (`main/1`)
  - Errors bubble up through return values, not exceptions
  """

  # =============================================================================
  # Type Definitions
  # =============================================================================

  @typedoc "A function that processes a string and produces a side effect"
  @type processor :: (String.t() -> any())

  @typedoc "Standard result tuple for operations that can fail"
  @type result :: {:ok, any()} | {:error, atom() | String.t()}

  @typedoc "Parsed command-line arguments"
  @type parsed_args :: :help | {:file, String.t()}

  # =============================================================================
  # Public API
  # =============================================================================

  @doc """
  Main entry point for the escript.

  Parses command-line arguments, executes the appropriate action, and sets
  the process exit code based on the result.

  ## Exit Codes

  - `0` - Success (including `--help`)
  - `1` - Error (file not found, read error, etc.)

  ## Examples

      # From the command line:
      $ elixir_file_scratch --file /tmp/example.txt
      $ elixir_file_scratch -f /tmp/example.txt
      $ elixir_file_scratch --help

  ## Design Note

  `System.halt/1` is called only here at the top level, keeping all other
  functions pure and testable. This is the "imperative shell" that wraps
  our "functional core".
  """
  @spec main([String.t()]) :: no_return() | :ok
  def main(args) do
    args
    |> parse_args()
    |> execute()
    |> handle_exit()
  end

  @doc """
  Reads an entire file into memory and processes its contents.

  Reads the file as a single string and passes it to the processor function.
  Use this for small files where you need the complete contents at once.

  ## Parameters

  - `filename` - Path to the file to read
  - `processor` - Function that receives the file contents as a string

  ## Returns

  - `{:ok, contents}` - The raw file contents (processor's return value is ignored)
  - `{:error, reason}` - An atom describing why the read failed (e.g., `:enoent`, `:eacces`)

  ## Examples

      iex> ElixirFileScratch.read_all("/tmp/hello.txt", &IO.puts/1)
      Hello, World!
      {:ok, "Hello, World!\\n"}

      iex> ElixirFileScratch.read_all("/nonexistent", &IO.puts/1)
      {:error, :enoent}

  ## When to Use

  - Small files that fit comfortably in memory
  - When you need the complete contents for processing (e.g., parsing JSON)
  - When line-by-line processing isn't necessary
  """
  @spec read_all(Path.t(), processor()) :: result()
  def read_all(filename, processor) do
    case File.read(filename) do
      {:ok, contents} ->
        processor.(contents)
        {:ok, contents}

      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Reads a file line by line and processes each line.

  Uses `File.stream!/1` for memory-efficient processing of large files.
  Each line is trimmed of trailing whitespace before being passed to
  the processor.

  ## Parameters

  - `filename` - Path to the file to read
  - `processor` - Function called for each line (receives trimmed line)

  ## Returns

  - `{:ok, lines}` - List of all trimmed lines
  - `{:error, reason}` - An atom describing why the operation failed

  ## Examples

      iex> ElixirFileScratch.read_line_by_line("/tmp/names.txt", &IO.puts/1)
      Alice
      Bob
      Charlie
      {:ok, ["Alice", "Bob", "Charlie"]}

      iex> ElixirFileScratch.read_line_by_line("/nonexistent", &IO.puts/1)
      {:error, :enoent}

  ## When to Use

  - Large files that shouldn't be loaded entirely into memory
  - When processing can happen line-by-line
  - Log files, CSVs, or other line-oriented formats

  ## Implementation Note

  We check `File.stat/1` first to return a clean `{:error, reason}` tuple.
  `File.stream!/1` would raise an exception on missing files, which doesn't
  fit our error-handling pattern.
  """
  @spec read_line_by_line(Path.t(), processor()) :: result()
  def read_line_by_line(filename, processor) do
    case File.stat(filename) do
      {:ok, _stat} ->
        lines =
          filename
          |> File.stream!()
          |> Enum.map(&process_line(&1, processor))

        {:ok, lines}

      {:error, _reason} = error ->
        error
    end
  end

  # =============================================================================
  # Private Functions - Argument Parsing
  # =============================================================================

  @spec parse_args([String.t()]) :: parsed_args()
  defp parse_args(args) do
    {opts, _remaining, _invalid} =
      OptionParser.parse(args,
        strict: [help: :boolean, file: :string],
        aliases: [h: :help, f: :file]
      )

    cond do
      opts[:help] -> :help
      opts[:file] -> {:file, opts[:file]}
      true -> :help
    end
  end

  # =============================================================================
  # Private Functions - Command Execution
  # =============================================================================

  @spec execute(parsed_args()) :: result()
  defp execute(:help) do
    print_help()
    :ok
  end

  defp execute({:file, filename}) do
    process(filename)
  end

  @spec process(Path.t()) :: result()
  defp process(filename) do
    with {:ok, _content} <- read_all(filename, &print_line/1),
         :ok <- IO.puts("--- Finished read_all for #{filename} ---"),
         {:ok, _lines} <- read_line_by_line(filename, &print_line/1),
         :ok <- IO.puts("--- Finished read_line_by_line for #{filename} ---") do
      :ok
    else
      {:error, reason} ->
        IO.puts(:stderr, "Error reading file '#{filename}': #{format_error(reason)}")
        {:error, reason}
    end
  end

  # =============================================================================
  # Private Functions - Output & Formatting
  # =============================================================================

  @spec print_line(String.t()) :: :ok
  defp print_line(text) do
    IO.puts(text)
  end

  @spec process_line(String.t(), processor()) :: String.t()
  defp process_line(line, processor) do
    trimmed = String.trim_trailing(line)
    processor.(trimmed)
    trimmed
  end

  @spec format_error(atom() | String.t()) :: String.t()
  defp format_error(:enoent), do: "file not found"
  defp format_error(:eacces), do: "permission denied"
  defp format_error(:eisdir), do: "is a directory"
  defp format_error(:enotdir), do: "not a directory"
  defp format_error(:enomem), do: "not enough memory"
  defp format_error(reason), do: inspect(reason)

  @spec print_help() :: :ok
  defp print_help do
    IO.puts("""
    ElixirFileScratch - A file reading demonstration tool

    Usage:
        elixir_file_scratch [options]

    Options:
        -f, --file <filename>    Specify a file to process
        -h, --help               Show this help message

    Examples:
        elixir_file_scratch --file /tmp/foo.txt
        elixir_file_scratch -f /tmp/foo.txt

    Exit Codes:
        0    Success
        1    Error (file not found, permission denied, etc.)
    """)
  end

  # =============================================================================
  # Private Functions - Exit Handling
  # =============================================================================

  @spec handle_exit(result() | :ok) :: :ok | no_return()
  defp handle_exit(:ok), do: :ok
  defp handle_exit({:ok, _}), do: :ok
  defp handle_exit({:error, _}), do: System.halt(1)
end
