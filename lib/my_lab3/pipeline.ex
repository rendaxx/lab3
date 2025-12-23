defmodule MyLab3.Pipeline do
  @moduledoc """
  Spawns the streaming processes and waits for completion.
  """

  alias MyLab3.Parser
  alias MyLab3.Pipeline.{Coordinator, Printer, Reader}
  alias MyLab3.Worker

  @spec run(map(), IO.device(), IO.device(), IO.device()) :: non_neg_integer()
  def run(opts, input_device, output_device, err_device) do
    parent = self()
    algo_count = length(opts.algorithms)

    printer =
      Printer.start(%{
        output: output_device,
        err: err_device,
        expected: algo_count,
        precision: opts.precision,
        format: opts.format,
        parent: parent
      })

    coordinator = Coordinator.start(printer, parent)

    workers =
      Worker.start_all(opts.algorithms,
        printer: printer,
        coordinator: coordinator,
        step: opts.step,
        window: opts.window
      )

    send(coordinator, {:set_workers, workers})
    Reader.start(input_device, coordinator, opts.delimiter)

    wait_for_completion(%{exit_code: 0, printer_done: false, coordinator_done: false})
  end

  defp wait_for_completion(%{printer_done: true, coordinator_done: true, exit_code: code}), do: code

  defp wait_for_completion(state) do
    receive do
      {:fatal, _reason} ->
        wait_for_completion(%{state | exit_code: 1})

      {:printer_done, _pid} ->
        wait_for_completion(%{state | printer_done: true})

      {:coordinator_done, _pid} ->
        wait_for_completion(%{state | coordinator_done: true})
    end
  end

  defmodule Reader do
    @moduledoc false

    def start(input_device, coordinator, delimiter) do
      spawn(fn -> loop(input_device, coordinator, delimiter, 0) end)
    end

    defp loop(input_device, coordinator, delimiter, line_no) do
      case IO.read(input_device, :line) do
        :eof ->
          send(coordinator, :eof)

        {:error, reason} ->
          send(coordinator, {:reader_error, "io error: #{inspect(reason)}"})

        data ->
          new_line_no = line_no + 1

          case Parser.parse_line(data, delimiter) do
            {:ok, {x, y}} ->
              send(coordinator, {:point, x, y})
              loop(input_device, coordinator, delimiter, new_line_no)

            :skip ->
              loop(input_device, coordinator, delimiter, new_line_no)

            {:error, message} ->
              send(coordinator, {:reader_error, "line #{new_line_no}: #{message}"})
          end
      end
    end
  end

  defmodule Coordinator do
    @moduledoc false

    def start(printer, parent) do
      spawn(fn ->
        loop(%{
          parent: parent,
          printer: printer,
          workers: [],
          worker_count: 0,
          done: 0,
          last_x: nil,
          aborted: false
        })
      end)
    end

    defp loop(state) do
      receive do
        {:set_workers, workers} ->
          loop(%{state | workers: workers, worker_count: length(workers)})

        {:point, x, y} ->
          handle_point(x, y, state)

        :eof ->
          if state.aborted do
            finish(state)
          else
            Enum.each(state.workers, fn {_name, pid} -> send(pid, :eof) end)
            loop(state)
          end

        {:algo_done, _name} ->
          done = state.done + 1

          if done >= state.worker_count do
            finish(%{state | done: done})
          else
            loop(%{state | done: done})
          end

        {:reader_error, message} ->
          abort(state, message)

        {:abort, message} ->
          abort(state, message)
      end
    end

    defp handle_point(_x, _y, %{aborted: true} = state), do: loop(state)

    defp handle_point(x, y, state) do
      cond do
        state.worker_count == 0 ->
          abort(state, "no algorithms enabled")

        state.last_x && x <= state.last_x ->
          abort(state, "non-increasing x value #{x}")

        true ->
          Enum.each(state.workers, fn {_name, pid} -> send(pid, {:in_point, x, y}) end)
          loop(%{state | last_x: x})
      end
    end

    defp abort(state, reason) do
      send(state.parent, {:fatal, reason})
      send(state.printer, {:abort, reason})
      Enum.each(state.workers, fn {_name, pid} -> send(pid, :abort) end)
      finish(%{state | aborted: true})
    end

    defp finish(state) do
      send(state.parent, {:coordinator_done, self()})
    end
  end

  defmodule Printer do
    @moduledoc false

    alias MyLab3.Formatter

    def start(%{
          output: output_device,
          err: err_device,
          expected: expected,
          precision: precision,
          format: format,
          parent: parent
        }) do
      spawn(fn ->
        loop(%{
          output: output_device,
          err: err_device,
          expected: expected,
          precision: precision,
          format: format,
          done: 0,
          parent: parent
        })
      end)
    end

    defp loop(state) do
      receive do
        {:out, algo, x, y} ->
          IO.write(state.output, Formatter.format_out(algo, x, y, state.precision, state.format))
          loop(state)

        {:algo_done, _algo} ->
          done = state.done + 1

          if done >= state.expected do
            send(state.parent, {:printer_done, self()})
          else
            loop(%{state | done: done})
          end

        {:abort, reason} ->
          IO.write(state.err, "error: #{reason}\n")
          send(state.parent, {:printer_done, self()})
      end
    end
  end
end
