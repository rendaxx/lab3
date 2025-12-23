defmodule MyLab3.Worker do
  @moduledoc false

  alias MyLab3.Worker.{Linear, Newton}

  def start_all(algorithms, opts) do
    Enum.map(algorithms, fn
      :linear ->
        {:linear, Linear.start(opts[:printer], opts[:coordinator], opts[:step])}

      :newton ->
        {:newton,
         Newton.start(opts[:printer], opts[:coordinator], opts[:step], opts[:window] || 4)}
    end)
  end
end
