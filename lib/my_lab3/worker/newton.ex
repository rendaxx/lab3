defmodule MyLab3.Worker.Newton do
  @moduledoc false

  alias MyLab3.Interpolation.Newton
  alias MyLab3.Sampler

  def start(printer, coordinator, step, window) do
    spawn(fn ->
      loop(%{
        printer: printer,
        coordinator: coordinator,
        step: step,
        window: window,
        points: [],
        next_x: nil,
        prev_center: nil
      })
    end)
  end

  defp loop(state) do
    receive do
      {:in_point, x, y} ->
        loop(handle_point(state, {x, y}))

      :eof ->
        state
        |> finalize_ready_windows()
        |> finalize_remaining()
        |> send_done()

      :abort ->
        send_done(state)
    end
  end

  defp handle_point(state, point) do
    state = %{state | points: state.points ++ [point]}
    finalize_ready_windows(state)
  end

  defp finalize_ready_windows(%{points: points, window: window} = state) do
    if length(points) >= window + 1 do
      state
      |> finalize_window(false)
      |> finalize_ready_windows()
    else
      state
    end
  end

  defp finalize_remaining(%{points: points, window: window} = state) do
    if length(points) >= window do
      state
      |> finalize_window(true)
      |> finalize_remaining()
    else
      state
    end
  end

  defp finalize_window(state, inclusive_right) do
    window_points = Enum.take(state.points, state.window)
    center = window_center(window_points, state.window)

    next_window_points = Enum.slice(state.points, 1, state.window)
    right_center = if length(next_window_points) == state.window, do: window_center(next_window_points, state.window)

    left_boundary = state.prev_center || first_x(window_points)
    right_boundary = right_boundary(center, right_center, last_x(window_points))
    inclusive = inclusive_right or right_center == nil

    {outputs, next_x} =
      sample_window(window_points, left_boundary, right_boundary, state.next_x, state.step, inclusive)

    Enum.each(outputs, fn {x, y} ->
      send(state.printer, {:out, "newton", x, y})
    end)

    %{state | points: tl(state.points), next_x: next_x, prev_center: center}
  end

  defp sample_window(points, left, right, next_x, step, inclusive) do
    coeffs = Newton.coefficients(points)
    xs = Enum.map(points, fn {x, _y} -> x end)
    Sampler.sample_interval(left, right, next_x, step, inclusive, fn x -> Newton.eval(coeffs, xs, x) end)
  end

  defp window_center(points, window) do
    mid = div(window, 2)

    if rem(window, 2) == 1 do
      elem(Enum.at(points, mid), 0)
    else
      {x0, _} = Enum.at(points, mid - 1)
      {x1, _} = Enum.at(points, mid)
      (x0 + x1) / 2
    end
  end

  defp first_x(points), do: points |> hd() |> elem(0)
  defp last_x(points), do: points |> List.last() |> elem(0)

  defp right_boundary(_center, nil, last_x), do: last_x
  defp right_boundary(center, next_center, _last_x), do: (center + next_center) / 2

  defp send_done(state) do
    send(state.printer, {:algo_done, "newton"})
    send(state.coordinator, {:algo_done, :newton})
  end
end
