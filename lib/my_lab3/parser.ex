defmodule MyLab3.Parser do
  @moduledoc """
  Input parsing helpers.
  """

  @type delimiter_option :: :auto | :comma | :semicolon | :tab | :space

  @spec parse_line(String.t(), delimiter_option()) ::
          :skip | {:ok, {float(), float()}} | {:error, String.t()}
  def parse_line(line, delimiter_option) do
    trimmed = String.trim(line)

    cond do
      trimmed == "" -> :skip
      String.starts_with?(trimmed, "#") -> :skip
      true -> split_and_parse(trimmed, delimiter_option)
    end
  end

  defp split_and_parse(trimmed, delimiter_option) do
    parts =
      trimmed
      |> String.split(splitter(delimiter_option), trim: true)
      |> Enum.reject(&(&1 == ""))

    case parts do
      [sx, sy] ->
        with {:ok, x} <- parse_float(sx),
             {:ok, y} <- parse_float(sy) do
          {:ok, {x, y}}
        end

      _ ->
        {:error, "expected two numeric columns"}
    end
  end

  defp parse_float(value) do
    case Float.parse(value) do
      {number, ""} -> {:ok, number}
      {_number, rest} -> {:error, "invalid number #{inspect(value)} (trailing #{inspect(rest)})"}
      :error -> {:error, "invalid number #{inspect(value)}"}
    end
  end

  defp splitter(:auto), do: ~r/[,\s;]+/
  defp splitter(:comma), do: ","
  defp splitter(:semicolon), do: ";"
  defp splitter(:tab), do: ~r/\t+/
  defp splitter(:space), do: ~r/\s+/
end
