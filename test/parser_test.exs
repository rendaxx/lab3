defmodule MyLab3.ParserTest do
  use ExUnit.Case, async: true

  alias MyLab3.Parser

  test "parses space separated values" do
    assert Parser.parse_line("1.0 2.5", :space) == {:ok, {1.0, 2.5}}
  end

  test "parses comma with auto detection" do
    assert Parser.parse_line("3,4", :auto) == {:ok, {3.0, 4.0}}
  end

  test "parses semicolon" do
    assert Parser.parse_line("5;6", :semicolon) == {:ok, {5.0, 6.0}}
  end

  test "ignores comments and blanks" do
    assert Parser.parse_line("# comment", :auto) == :skip
    assert Parser.parse_line("   ", :auto) == :skip
  end

  test "returns error on malformed lines" do
    assert {:error, _} = Parser.parse_line("foo bar", :auto)
    assert {:error, _} = Parser.parse_line("1", :auto)
  end
end
