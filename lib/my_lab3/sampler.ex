defmodule MyLab3.Sampler do
  @moduledoc """
  Helper for sampling interpolation functions on a fixed grid without duplicates.
  """

  @epsilon 1.0e-9

  @spec sample_interval(
          float(),
          float(),
          float() | nil,
          float(),
          boolean(),
          (float() -> float())
        ) :: {list({float(), float()}), float()}
  def sample_interval(left, right, next_x, step, inclusive_right, fun) do
    base = init_next_x(left, step)
    start_x = max(next_x || base, base)
    do_sample(start_x, right, step, inclusive_right, fun, [], nil)
  end

  @spec init_next_x(float(), float()) :: float()
  def init_next_x(left, step) do
    Float.ceil(left / step) * step
  end

  defp do_sample(x, right, step, inclusive_right, fun, acc, last_out) do
    cond do
      x < right ->
        y = fun.(x)
        do_sample(x + step, right, step, inclusive_right, fun, [{x, y} | acc], x)

      inclusive_right and close_enough(x, right) ->
        y = fun.(right)
        {Enum.reverse([{right, y} | acc]), right + step}

      true ->
        next = if last_out, do: last_out + step, else: x
        {Enum.reverse(acc), next}
    end
  end

  defp close_enough(a, b) do
    abs(a - b) <= @epsilon * Enum.max([1.0, abs(a), abs(b)])
  end
end
