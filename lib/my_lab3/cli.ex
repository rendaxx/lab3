defmodule MyLab3.CLI do
  @moduledoc """
  Command line interface for the streaming interpolation lab.
  """

  alias MyLab3.Pipeline

  @defaults %{
    window: 4,
    step: 0.5,
    delimiter: :auto,
    precision: 12,
    format: :space
  }

  @spec main([String.t()]) :: no_return()
  def main(argv) do
    argv
    |> run()
    |> System.halt()
  end

  @spec run([String.t()], IO.device(), IO.device(), IO.device()) :: non_neg_integer()
  def run(argv, input_device \\ :stdio, output_device \\ :stdio, err_device \\ :stderr) do
    case parse_args(argv) do
      :help ->
        IO.puts(output_device, help_text())
        0

      {:error, message} ->
        IO.puts(err_device, "error: #{message}")
        1

      {:ok, opts} ->
        Pipeline.run(opts, input_device, output_device, err_device)
    end
  end

  defp parse_args(argv) do
    {parsed, _rest, invalid} =
      OptionParser.parse(argv,
        switches: [
          linear: :boolean,
          newton: :boolean,
          window: :integer,
          step: :float,
          delimiter: :string,
          precision: :integer,
          format: :string,
          help: :boolean
        ],
        aliases: [n: :window]
      )

    cond do
      parsed[:help] ->
        :help

      invalid != [] ->
        {:error, "invalid arguments: #{inspect(invalid)}"}

      true ->
        build_options(parsed)
    end
  end

  defp build_options(parsed) do
    algorithms = pick_algorithms(parsed)
    step = parsed[:step] || @defaults.step

    cond do
      step <= 0 ->
        {:error, "--step must be > 0"}

      window_invalid?(parsed[:window] || @defaults.window) ->
        {:error, "--window must be an integer >= 2"}

      true ->
        with {:ok, delimiter} <- parse_delimiter(parsed[:delimiter]),
             {:ok, format} <- parse_format(parsed[:format]) do
          {:ok,
           %{
             algorithms: algorithms,
             window: parsed[:window] || @defaults.window,
             step: step,
             delimiter: delimiter,
             precision: parsed[:precision] || @defaults.precision,
             format: format
           }}
        end
    end
  end

  defp pick_algorithms(parsed) do
    []
    |> add_if(parsed[:linear], :linear)
    |> add_if(parsed[:newton], :newton)
    |> ensure_default()
  end

  defp add_if(list, true, item), do: [item | list]
  defp add_if(list, _flag, _item), do: list

  defp ensure_default([]), do: [:linear]
  defp ensure_default(list), do: Enum.reverse(list)

  defp window_invalid?(value), do: value < 2

  defp parse_delimiter(nil), do: {:ok, @defaults.delimiter}
  defp parse_delimiter("auto"), do: {:ok, :auto}
  defp parse_delimiter("comma"), do: {:ok, :comma}
  defp parse_delimiter("semicolon"), do: {:ok, :semicolon}
  defp parse_delimiter("tab"), do: {:ok, :tab}
  defp parse_delimiter("space"), do: {:ok, :space}
  defp parse_delimiter(other), do: {:error, "unknown delimiter #{inspect(other)}"}

  defp parse_format(nil), do: {:ok, @defaults.format}
  defp parse_format("space"), do: {:ok, :space}
  defp parse_format("csv"), do: {:ok, :csv}
  defp parse_format("tsv"), do: {:ok, :tsv}
  defp parse_format(other), do: {:error, "unknown format #{inspect(other)}"}

  defp help_text do
    """
    Usage: my_lab3 [options]

    Flags:
      --linear              Enable piecewise linear interpolation (default when no flags)
      --newton              Enable Newton sliding window interpolation
      -n, --window N        Window size for Newton (default #{@defaults.window})
      --step S              Sampling step for output x values (default #{@defaults.step})
      --delimiter MODE      Input delimiter: auto|comma|semicolon|tab|space (default #{@defaults.delimiter})
      --precision K         Significant digits for output (default #{@defaults.precision})
      --format FORMAT       Output format: space|csv|tsv (default #{@defaults.format})
      --help                Show this message

    Examples:
      cat points.txt | ./my_lab3 --linear --step 0.7
      cat points.txt | ./my_lab3 --newton --window 4 --step 0.5
      cat points.txt | ./my_lab3 --linear --newton --step 1.0
    """
  end
end
