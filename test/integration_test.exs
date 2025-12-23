defmodule MyLab3.IntegrationTest do
  use ExUnit.Case

  alias MyLab3.CLI

  test "streams both algorithms with monotonic x" do
    input = """
    0 0
    1 1
    2 4
    3 9
    """

    {:ok, input_dev} = StringIO.open(input)
    {:ok, output_dev} = StringIO.open("")
    {:ok, err_dev} = StringIO.open("")

    exit_code =
      CLI.run(
        ["--linear", "--newton", "--window", "4", "--step", "1.0"],
        input_dev,
        output_dev,
        err_dev
      )

    assert exit_code == 0

    {_in, output} = StringIO.contents(output_dev)
    {_err_in, err_output} = StringIO.contents(err_dev)
    assert err_output == ""

    lines = output |> String.trim() |> String.split("\n", trim: true)
    parsed = Enum.map(lines, &parse_line/1)
    grouped = Enum.group_by(parsed, fn {algo, _pt} -> algo end, fn {_algo, pt} -> pt end)

    linear_points = Map.fetch!(grouped, "linear")
    newton_points = Map.fetch!(grouped, "newton")

    assert monotonic?(linear_points)
    assert monotonic?(newton_points)
    assert unique?(linear_points)
    assert unique?(newton_points)

    assert linear_points == [{0.0, 0.0}, {1.0, 1.0}, {2.0, 4.0}]

    assert Enum.any?(newton_points, fn {x, y} ->
             x == 3.0 and abs(y - 9.0) < 1.0e-6
           end)
  end

  defp parse_line(line) do
    [algo, rest] = String.split(line, ": ", parts: 2)
    [x_str, y_str] = String.split(rest, ~r/[\s,]+/, trim: true)
    {algo, {String.to_float(x_str), String.to_float(y_str)}}
  end

  defp monotonic?(points) do
    xs = Enum.map(points, fn {x, _} -> x end)
    xs == Enum.sort(xs)
  end

  defp unique?(points) do
    xs = Enum.map(points, fn {x, _} -> x end)
    length(xs) == length(Enum.uniq(xs))
  end
end
