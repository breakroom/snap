defmodule Snap.MixProject do
  use Mix.Project

  @github_url "https://github.com/breakroom/snap"
  @version "0.5.1"

  def project do
    [
      app: :snap,
      name: "Snap",
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      dialyzer: dialyzer(),

      # Hex
      description: "A modern Elasticsearch client",
      package: package(),

      # Docs
      source_url: @github_url,
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(env) when env in ~w(test)a, do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp dialyzer do
    [
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.8"},
      {:castore, "~> 0.1"},
      {:jason, "~> 1.0"},
      {:telemetry, "~> 1.0"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Tom Taylor"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @github_url
      },
      files: ~w(mix.exs lib LICENSE.md README.md CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "Snap",
      source_ref: @version,
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
        ],
        "Response structs": [
          Snap.SearchResponse,
          Snap.Hits,
          Snap.Hit
        ],
        Exceptions: [
          Snap.ResponseError,
          Snap.BulkError
        ]
      ]
    ]
  end
end
