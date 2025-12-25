defmodule ElixirFileScratch do
  @moduledoc """
  Documentation for `ElixirFileScratch`.
  """
  defp shout(s) do
    IO.puts(s)
    nil
  end

  def read_all(filename, processor) do
    case File.read(filename) do
      {:ok, contents} ->
        processor.(contents)

      {:error, reason} ->
        IO.puts("Error reading file: #{reason}")
        nil
    end
  end

  def read_line_by_line(filename, processor) do
    case File.stat(filename) do
      {:ok, _stat} ->
          filename
          |> File.stream!()
          |> Enum.map(fn line ->
            trimmed = String.trim_trailing(line)
            processor.(trimmed)
          end)

      {:error, reason} ->
        IO.puts("Error opening file: #{reason}")
        nil
    end
  end

  @doc """
  Main entry point for the escript.
  Parses command-line arguments and executes the appropriate action.
  """
  def main(args) do
    args
    |> parse_args()
    |> case do
      :help -> print_help()
      {:file, f} -> process(f)
    end
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

  defp process(filename) do
    case read_all(filename, &shout/1) do
      {:ok, content} ->
        IO.puts("File contents of #{filename}:")
        IO.puts(content)

      {:error, reason} ->
        IO.puts(:stderr, "Error reading file '#{filename}': #{inspect(reason)}")
        System.halt(1)
    end

    case read_line_by_line(filename, &shout/1) do
      {:ok, content} ->
        IO.puts("File contents of #{filename}:")
        IO.puts(content)

      {:error, reason} ->
        IO.puts(:stderr, "Error reading file '#{filename}': #{inspect(reason)}")
        System.halt(1)
    end

    nil
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
