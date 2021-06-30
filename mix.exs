defmodule Disssim.MixProject do
  use Mix.Project

  def project do
    [
      app: :disssim,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:uuid, "~> 1.1"},
      {:poolboy, "~> 1.5"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end
end
