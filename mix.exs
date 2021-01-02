defmodule Snap.MixProject do
  use Mix.Project

  def project do
    [
      app: :snap,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      name: "Snap",
      source_url: "https://github.com/tomtaylor/snap",
      docs: [
        main: "Snap",
        groups_for_modules: [
          Authentication: [
            Snap.Auth,
            Snap.Auth.Plain
          ],
          "Bulk operations": [
            Snap.Bulk.Action.Create,
            Snap.Bulk.Action.Index,
            Snap.Bulk.Action.Update,
            Snap.Bulk.Action.Delete
          ]
        ]
      ]
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
      {:finch, "~> 0.6"},
      {:castore, "~> 0.1.0"},
      {:jason, "~> 1.0"},
      {:telemetry, "~> 0.4"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
    ]
  end
end
