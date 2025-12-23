defmodule MyLab3.Formatter do
  @moduledoc """
  Output formatting utilities.
  """

  @spec format_out(String.t(), float(), float(), pos_integer(), atom()) :: iodata()
  def format_out(algo, x, y, precision, format) do
    sep = separator(format)

    [
      algo,
      ": ",
      format_float(x, precision),
      sep,
      format_float(y, precision),
      "\n"
    ]
  end

  defp separator(:space), do: " "
  defp separator(:csv), do: ","
  defp separator(:tsv), do: "\t"

  defp format_float(value, precision) do
    value
    |> then(fn number -> :io_lib.format(~c"~.*g", [precision, number]) end)
    |> IO.iodata_to_binary()
  end
end
