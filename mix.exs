defmodule MyLab3.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_lab3,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: MyLab3.CLI, name: "my_lab3"]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
