defmodule Snap.MixProject do
  use Mix.Project

  @github_url "https://github.com/breakroom/snap"
  @version "0.10.1"

  def project do
    [
      app: :snap,
      name: "Snap",
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      dialyzer: dialyzer(),
      aliases: aliases(),
      preferred_cli_env: ["test.all": :test],

      # Hex
      description: "A modern Elasticsearch client",
      package: package(),

      # Docs
      source_url: @github_url,
      docs: docs(),

      # Suppress warnings
      xref: [
        exclude: [
          Finch
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

  defp elixirc_paths(env) when env in ~w(test)a, do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp dialyzer do
    [
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:finch]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.8", optional: true},
      {:castore, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:telemetry, "~> 1.0 or ~> 0.4"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      dev: "run --no-halt dev.exs",
      "test.all": ["test --include integration"]
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
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: @version,
      groups_for_modules: [
        Authentication: [
          Snap.Auth,
          Snap.Auth.Plain
        ],
        "HTTP Client": [
          Snap.HTTPClient,
          Snap.HTTPClient.Response,
          Snap.HTTPClient.Adapters.Finch
        ],
        "Bulk operations": [
          Snap.Bulk.Action.Create,
          Snap.Bulk.Action.Index,
          Snap.Bulk.Action.Update,
          Snap.Bulk.Action.Delete
        ],
        "Multi search API": [
          Snap.Multi,
          Snap.Multi.Response
        ],
        "Response structs": [
          Snap.Aggregation,
          Snap.Hit,
          Snap.Hits,
          Snap.SearchResponse,
          Snap.Suggest,
          Snap.Suggest.Option,
          Snap.Suggest.Options,
          Snap.Suggests
        ],
        Exceptions: [
          Snap.ResponseError,
          Snap.BulkError,
          Snap.HTTPClient.Error,
          Snap.HTTPError
        ]
      ]
    ]
  end
end
