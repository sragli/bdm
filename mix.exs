defmodule BDM.MixProject do
  use Mix.Project

  def project do
    [
      app: :bdm,
      version: "0.2.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "BDM",
      source_url: "https://github.com/sragli/bdm",
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    "Elixir module that implements the Block Decomposition Method."
  end

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/sragli/bdm"}
    ]
  end

  defp docs() do
    [
      main: "BDM",
      extras: ["README.md", "LICENSE", "examples.livemd", "CHANGELOG"]
    ]
  end

  defp deps do
    [
      {:nx, "~> 0.10.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
