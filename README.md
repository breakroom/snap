# Snap

[![Hex pm](http://img.shields.io/hexpm/v/snap.svg?style=flat)](https://hex.pm/packages/snap)

Snap is an Elasticsearch client. It provides a flexible, performant API on
top of your Elasticsearch cluster, supporting high level features like
versioned index management, while also providing a convenient interface into
low level operations.

See the full [API docs](https://hexdocs.pm/snap).

**Disclaimer**: Snap is new and may not be production ready yet.

## Features

- Versioned index management with zero-downtime hotswapping (compatible with [`elasticsearch`](https://github.com/danielberkompas/elasticsearch-elixir))
- Streaming bulk operations
- Connection pooling
- Telemetry events

## Installation

The package can be installed by adding `snap` to your list of dependencies in
`mix.exs`:

```elixir
def deps do
  [
    {:snap, "~> 0.2.3"}
  ]
end
```

Snap supports Elixir 1.9 or later. It might work with earlier versions but is currently untested.

## Usage

Implement your own cluster module, similar to an `Ecto.Repo`:

```elixir
defmodule MyApp.Cluster do
  use Snap.Cluster, otp_app: :my_app
end
```

Configure it:

```elixir
config :my_app, MyApp.Cluster,
  url: "http://localhost:9200",
  username: "my_username",
  password: "my_password"
```

Then wire it into your application supervisor:

```elixir
def start(_type, _args) do
  children = [
    {MyApp.Cluster, []}
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

Now you can perform operations on your cluster:

```elixir
{:ok, %{"count" => count}} = MyApp.Cluster.get("/my-index/_count")
```

See the [API documentation](https://hexdocs.pm/snap) for more advanced features.
