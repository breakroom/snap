defmodule Snap.MixProject do
  use Mix.Project

  def project do
    [
      app: :snap,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(env) when env in ~w(test dev)a, do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mint, "~> 1.0"},
      {:castore, "~> 0.1.0"},
      {:poolboy, "~> 1.5.1"},
      {:jason, "~> 1.0"},
      {:telemetry, "~> 0.4"}
    ]
  end
end
