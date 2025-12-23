defmodule MyLab3.Interpolation.Linear do
  @moduledoc """
  Piecewise linear interpolation helpers.
  """

  @spec interp({float(), float()}, {float(), float()}, float()) :: float()
  def interp({x0, y0}, {x1, y1}, x) do
    slope = (y1 - y0) / (x1 - x0)
    y0 + slope * (x - x0)
  end
end
