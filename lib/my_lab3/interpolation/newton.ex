defmodule MyLab3.Interpolation.Newton do
  @moduledoc """
  Divided differences and evaluation for Newton polynomials.
  """

  @spec coefficients(list({float(), float()})) :: list(float())
  def coefficients(points) do
    xs = Enum.map(points, fn {x, _y} -> x end)
    ys = Enum.map(points, fn {_x, y} -> y end)

    build(xs, ys, [], 0)
  end

  @spec eval(list(float()), list(float()), float()) :: float()
  def eval([], _xs, _x), do: 0.0

  def eval(coeffs, xs, x) do
    bases = Enum.take(xs, max(length(coeffs) - 1, 0))
    [last_coeff | rest_coeffs] = Enum.reverse(coeffs)
    reversed_bases = Enum.reverse(bases)

    Enum.reduce(Enum.zip(rest_coeffs, reversed_bases), last_coeff, fn {coeff, base}, acc ->
      acc * (x - base) + coeff
    end)
  end

  defp build(xs, current, acc, order) do
    acc = acc ++ [hd(current)]

    if length(current) == 1 do
      acc
    else
      next =
        current
        |> Enum.with_index()
        |> Enum.reduce([], fn {y0, idx}, diffs ->
          case Enum.at(current, idx + 1) do
            nil ->
              diffs

            y1 ->
              denom = Enum.at(xs, idx + order + 1) - Enum.at(xs, idx)
              diffs ++ [(y1 - y0) / denom]
          end
        end)

      build(xs, next, acc, order + 1)
    end
  end
end
