defmodule Distopy.MixProject do
  use Mix.Project

  def project do
    [
      app: :distopy,
      consolidate_protocols: false,
      package: package(),
      version: "0.2.1",
      elixir: "~> 1.12",
      start_permanent: false,
      deps: deps(),
      docs: docs(),
      source_url: "https://github.com/lud/distopy"
    ]
  end

  def package do
    [
      links: %{"Github" => "https://github.com/lud/distopy"},
      description: "A command line tool to diff and fix .env files.",
      licenses: ["MIT"]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:dotenvy, "~> 0.5.0"},
      {:dialyxir, "~> 1.1", only: :dev},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: Distopy,
      source_ref: "main",
      formatters: ["html"],
      nest_modules_by_prefix: [],
      groups_for_functions: ["Source group callbacks": &(&1[:group] == true)]
    ]
  end
end
