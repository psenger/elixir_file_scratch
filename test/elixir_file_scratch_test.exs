defmodule ElixirFileScratchTest do
  use ExUnit.Case
  # Note: Doctests are skipped because they contain IO side effects and require files to exist
  # doctest ElixirFileScratch

  import ExUnit.CaptureIO

  # =============================================================================
  # Setup & Helpers
  # =============================================================================

  setup do
    # Create a temporary directory for test files
    tmp_dir = System.tmp_dir!()
    test_file = Path.join(tmp_dir, "elixir_file_scratch_test_#{:rand.uniform(100_000)}.txt")
    multi_line_file = Path.join(tmp_dir, "elixir_file_scratch_multi_#{:rand.uniform(100_000)}.txt")
    empty_file = Path.join(tmp_dir, "elixir_file_scratch_empty_#{:rand.uniform(100_000)}.txt")

    # Create test files
    File.write!(test_file, "Hello, World!")
    File.write!(multi_line_file, "Line 1\nLine 2\nLine 3\n")
    File.write!(empty_file, "")

    on_exit(fn ->
      File.rm(test_file)
      File.rm(multi_line_file)
      File.rm(empty_file)
    end)

    %{
      test_file: test_file,
      multi_line_file: multi_line_file,
      empty_file: empty_file,
      nonexistent_file: "/nonexistent/path/to/file_#{:rand.uniform(100_000)}.txt"
    }
  end

  # =============================================================================
  # Help Flag Tests
  # =============================================================================

  describe "main/1 with help flags" do
    test "prints help with --help flag" do
      output =
        capture_io(fn ->
          ElixirFileScratch.main(["--help"])
        end)

      assert output =~ "Usage:"
      assert output =~ "--file"
      assert output =~ "--help"
    end

    test "prints help with -h flag" do
      output =
        capture_io(fn ->
          ElixirFileScratch.main(["-h"])
        end)

      assert output =~ "Usage:"
    end

    test "prints help when no arguments given" do
      output =
        capture_io(fn ->
          ElixirFileScratch.main([])
        end)

      assert output =~ "Usage:"
    end

    test "help output includes examples" do
      output =
        capture_io(fn ->
          ElixirFileScratch.main(["--help"])
        end)

      assert output =~ "Examples:"
      assert output =~ "elixir_file_scratch --file"
    end

    test "help output includes exit codes" do
      output =
        capture_io(fn ->
          ElixirFileScratch.main(["--help"])
        end)

      assert output =~ "Exit Codes:"
      assert output =~ "0"
      assert output =~ "1"
    end
  end

  # =============================================================================
  # read_all/2 Tests
  # =============================================================================

  describe "read_all/2" do
    test "successfully reads file contents", %{test_file: test_file} do
      result = ElixirFileScratch.read_all(test_file, fn _ -> :ok end)

      assert {:ok, "Hello, World!"} = result
    end

    test "calls processor function with contents", %{test_file: test_file} do
      test_pid = self()

      ElixirFileScratch.read_all(test_file, fn contents ->
        send(test_pid, {:received, contents})
      end)

      assert_receive {:received, "Hello, World!"}
    end

    test "returns error for nonexistent file", %{nonexistent_file: nonexistent_file} do
      result = ElixirFileScratch.read_all(nonexistent_file, fn _ -> :ok end)

      assert {:error, :enoent} = result
    end

    test "reads empty file", %{empty_file: empty_file} do
      result = ElixirFileScratch.read_all(empty_file, fn _ -> :ok end)

      assert {:ok, ""} = result
    end

    test "reads multi-line file as single string", %{multi_line_file: multi_line_file} do
      result = ElixirFileScratch.read_all(multi_line_file, fn _ -> :ok end)

      assert {:ok, "Line 1\nLine 2\nLine 3\n"} = result
    end

    test "processor return value is ignored", %{test_file: test_file} do
      result = ElixirFileScratch.read_all(test_file, fn _ -> {:custom, :return} end)

      # Should still return the file contents, not the processor's return value
      assert {:ok, "Hello, World!"} = result
    end
  end

  # =============================================================================
  # read_line_by_line/2 Tests
  # =============================================================================

  describe "read_line_by_line/2" do
    test "successfully reads file line by line", %{multi_line_file: multi_line_file} do
      result = ElixirFileScratch.read_line_by_line(multi_line_file, fn _ -> :ok end)

      assert {:ok, ["Line 1", "Line 2", "Line 3"]} = result
    end

    test "calls processor function for each line", %{multi_line_file: multi_line_file} do
      test_pid = self()

      ElixirFileScratch.read_line_by_line(multi_line_file, fn line ->
        send(test_pid, {:line, line})
      end)

      assert_receive {:line, "Line 1"}
      assert_receive {:line, "Line 2"}
      assert_receive {:line, "Line 3"}
    end

    test "returns error for nonexistent file", %{nonexistent_file: nonexistent_file} do
      result = ElixirFileScratch.read_line_by_line(nonexistent_file, fn _ -> :ok end)

      assert {:error, :enoent} = result
    end

    test "reads empty file as empty list", %{empty_file: empty_file} do
      result = ElixirFileScratch.read_line_by_line(empty_file, fn _ -> :ok end)

      assert {:ok, []} = result
    end

    test "trims trailing whitespace from lines", %{multi_line_file: multi_line_file} do
      {:ok, lines} = ElixirFileScratch.read_line_by_line(multi_line_file, fn _ -> :ok end)

      # Lines should not have trailing newlines
      Enum.each(lines, fn line ->
        refute String.ends_with?(line, "\n")
      end)
    end

    test "single line file returns list with one element", %{test_file: test_file} do
      result = ElixirFileScratch.read_line_by_line(test_file, fn _ -> :ok end)

      assert {:ok, ["Hello, World!"]} = result
    end

    test "processor can transform lines", %{multi_line_file: multi_line_file} do
      {:ok, lines} =
        ElixirFileScratch.read_line_by_line(multi_line_file, fn line ->
          String.upcase(line)
        end)

      # The returned lines are the trimmed originals, not transformed
      assert lines == ["Line 1", "Line 2", "Line 3"]
    end
  end

  # =============================================================================
  # main/1 with --file Tests
  # =============================================================================

  describe "main/1 with --file flag" do
    test "processes file with --file flag", %{test_file: test_file} do
      output =
        capture_io(fn ->
          ElixirFileScratch.main(["--file", test_file])
        end)

      assert output =~ "Hello, World!"
      assert output =~ "Finished read_all"
      assert output =~ "Finished read_line_by_line"
    end

    test "processes file with -f flag", %{test_file: test_file} do
      output =
        capture_io(fn ->
          ElixirFileScratch.main(["-f", test_file])
        end)

      assert output =~ "Hello, World!"
    end

    test "processes multi-line file", %{multi_line_file: multi_line_file} do
      output =
        capture_io(fn ->
          ElixirFileScratch.main(["--file", multi_line_file])
        end)

      assert output =~ "Line 1"
      assert output =~ "Line 2"
      assert output =~ "Line 3"
    end
  end

  # =============================================================================
  # Error Handling Tests
  # =============================================================================

  describe "error handling" do
    test "read_all returns file not found error for nonexistent file", %{nonexistent_file: nonexistent_file} do
      # Test the underlying function directly to avoid System.halt(1) in main
      result = ElixirFileScratch.read_all(nonexistent_file, fn _ -> :ok end)
      assert {:error, :enoent} = result
    end

    test "read_line_by_line returns file not found error for nonexistent file", %{nonexistent_file: nonexistent_file} do
      result = ElixirFileScratch.read_line_by_line(nonexistent_file, fn _ -> :ok end)
      assert {:error, :enoent} = result
    end

    test "read_all returns error tuple for directory" do
      result = ElixirFileScratch.read_all(System.tmp_dir!(), fn _ -> :ok end)

      assert {:error, :eisdir} = result
    end

    test "read_line_by_line raises on directory input" do
      # File.stat returns :ok for directories, but File.stream! raises
      # This is expected behavior - streaming a directory is an error
      assert_raise File.Error, fn ->
        ElixirFileScratch.read_line_by_line(System.tmp_dir!(), fn _ -> :ok end)
      end
    end
  end

  # =============================================================================
  # Integration Tests
  # =============================================================================

  describe "integration" do
    test "read_all and read_line_by_line return consistent data", %{multi_line_file: multi_line_file} do
      {:ok, all_content} = ElixirFileScratch.read_all(multi_line_file, fn _ -> :ok end)
      {:ok, lines} = ElixirFileScratch.read_line_by_line(multi_line_file, fn _ -> :ok end)

      # Joining lines should give us the original content (minus trailing newlines)
      joined = Enum.join(lines, "\n")
      assert String.trim(all_content) == joined
    end

    test "both methods work with IO.puts as processor", %{test_file: test_file} do
      output_all =
        capture_io(fn ->
          ElixirFileScratch.read_all(test_file, &IO.puts/1)
        end)

      output_lines =
        capture_io(fn ->
          ElixirFileScratch.read_line_by_line(test_file, &IO.puts/1)
        end)

      assert output_all =~ "Hello, World!"
      assert output_lines =~ "Hello, World!"
    end
  end

  # =============================================================================
  # Edge Cases
  # =============================================================================

  describe "edge cases" do
    test "handles file with only newlines" do
      tmp_file = Path.join(System.tmp_dir!(), "newlines_only_#{:rand.uniform(100_000)}.txt")
      File.write!(tmp_file, "\n\n\n")

      on_exit(fn -> File.rm(tmp_file) end)

      {:ok, lines} = ElixirFileScratch.read_line_by_line(tmp_file, fn _ -> :ok end)

      # Each newline becomes an empty string after trimming
      assert lines == ["", "", ""]
    end

    test "handles file with special characters" do
      tmp_file = Path.join(System.tmp_dir!(), "special_chars_#{:rand.uniform(100_000)}.txt")
      content = "Hello\tWorld\r\nSpecial: @#$%^&*()"
      File.write!(tmp_file, content)

      on_exit(fn -> File.rm(tmp_file) end)

      {:ok, read_content} = ElixirFileScratch.read_all(tmp_file, fn _ -> :ok end)

      assert read_content == content
    end

    test "handles unicode content" do
      tmp_file = Path.join(System.tmp_dir!(), "unicode_#{:rand.uniform(100_000)}.txt")
      content = "Hello 世界! 🎉\nСпасибо\nありがとう"
      File.write!(tmp_file, content)

      on_exit(fn -> File.rm(tmp_file) end)

      {:ok, read_content} = ElixirFileScratch.read_all(tmp_file, fn _ -> :ok end)
      {:ok, lines} = ElixirFileScratch.read_line_by_line(tmp_file, fn _ -> :ok end)

      assert read_content == content
      assert lines == ["Hello 世界! 🎉", "Спасибо", "ありがとう"]
    end
  end
end
