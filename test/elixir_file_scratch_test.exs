defmodule ElixirFileScratchTest do
  use ExUnit.Case
  doctest ElixirFileScratch

  import ExUnit.CaptureIO

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
end
