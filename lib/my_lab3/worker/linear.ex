defmodule MyLab3.Worker.Linear do
  @moduledoc false

  alias MyLab3.Interpolation.Linear
  alias MyLab3.Sampler

  @spec start(any(), any(), any()) :: pid()
  def start(printer, coordinator, step) do
    spawn(fn ->
      loop(%{
        printer: printer,
        coordinator: coordinator,
        step: step,
        prev: nil,
        next_x: nil
      })
    end)
  end

  defp loop(state) do
    receive do
      {:in_point, x, y} ->
        loop(handle_point(state, {x, y}))

      :eof ->
        send_done(state)

      :abort ->
        send_done(state)
    end
  end

  defp handle_point(%{prev: nil} = state, point) do
    %{
      state
      | prev: point,
        next_x: state.next_x || Sampler.init_next_x(elem(point, 0), state.step)
    }
  end

  defp handle_point(state, point) do
    {outputs, next_x} = sample_segment(state.prev, point, state.next_x, state.step)

    Enum.each(outputs, fn {x, y} ->
      send(state.printer, {:out, "linear", x, y})
    end)

    %{state | prev: point, next_x: next_x}
  end

  defp sample_segment({x0, _y0} = p0, {x1, _y1} = p1, next_x, step) do
    Sampler.sample_interval(x0, x1, next_x, step, false, fn x -> Linear.interp(p0, p1, x) end)
  end

  defp send_done(state) do
    send(state.printer, {:algo_done, "linear"})
    send(state.coordinator, {:algo_done, :linear})
  end
end
