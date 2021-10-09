defmodule Distopy.MixProject do
  use Mix.Project

  def project do
    [
      app: :distopy,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: false,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:dotenvy, "~> 0.5.0"}
    ]
  end
end
