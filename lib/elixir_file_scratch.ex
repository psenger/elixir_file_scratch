defmodule ElixirFileScratch do
  @moduledoc """
  Documentation for `FileStream`.
  """

  @doc """
  Read a file line by lin ( Streaming )

  ## Examples

      iex> FileReader.read_line_by_line("example.txt")

  """
  def read_line_by_line(filename) do
    filename
    |> File.stream!()
    |> Enum.each(fn line ->
      # Process each line (e.g., trim newline and print)
      IO.puts("Line: #{String.trim_trailing(line)}")
    end)
  rescue
    e in File.Error ->
      IO.puts("Error opening file: #{e.reason}")
  end

  @doc """
  Read a file in its entirity ( slurp ).

  # Usage:
      iex> FileReader.read_all("example.txt")

  """
  def read_all(filename) do
    case File.read(filename) do
      {:ok, contents} ->
        IO.puts("File contents: #{contents}")
        # Return the contents if needed
        contents

      {:error, reason} ->
        IO.puts("Error reading file: #{reason}")
        nil
    end
  end

  @moduledoc """
  Documentation for `ElixirFileScratch`.
  A command-line tool for file operations.
  """

  @doc """
  Main entry point for the escript.
  Parses command-line arguments and executes the appropriate action.
  """
  def main(args) do
    args
    |> parse_args()
    |> process()
  end

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

  defp process(:help) do
    print_help()
  end

  defp process({:file, filename}) do
    case File.read(filename) do
      {:ok, content} ->
        IO.puts("File contents of #{filename}:")
        IO.puts(content)

      {:error, reason} ->
        IO.puts(:stderr, "Error reading file '#{filename}': #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp print_help do
    IO.puts("""
    Usage: elixir_file_scratch [options]

    Options:
      -f, --file <filename>    Specify a file to process
      -h, --help               Show this help message

    Examples:
      elixir_file_scratch --file /tmp/foo.txt
      elixir_file_scratch -f /tmp/foo.txt
    """)
  end
end
