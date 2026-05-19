# Snap

Snap is an Elasticsearch/OpenSearch client for Elixir.

## Common commands

```sh
mix test                              # unit tests only — integration tests excluded by default
mix test --include integration        # full suite; requires a running ES/OpenSearch on :9200
mix test.all                          # alias for the above
mix test path/to/file_test.exs:42     # single test by line number
mix format --check-formatted
mix credo                             # strict mode, see .credo.exs
mix dialyzer
```

Integration tests assume Elasticsearch/OpenSearch at `http://localhost:9200` and namespace their indexes with `snap-test` (see `test/test_helper.exs`).

## Architecture

### Cluster as the entry point

`Snap.Cluster` is a `__using__` macro (akin to `Ecto.Repo`). Consumers define `defmodule MyApp.Cluster do use Snap.Cluster, otp_app: :my_app end`, configure it via `Application` env, and add it to their supervisor.

`Snap.Cluster.Supervisor` is what actually starts: it boots a `Snap.Config` GenServer (holding the runtime config under `Module.concat(cluster, Config)`) plus the HTTP client child spec (if the adapter provides one).

### Request pipeline

All HTTP traffic flows through `Snap.Request.request/7` (`lib/snap/request.ex`):

### Namespacing

`Snap.Cluster.Namespace` provides two layers of index prefixing, and the convenience modules (`Snap.Bulk`, `Snap.Document`, `Snap.Indexes`, `Snap.Multi`, `Snap.Search`) all run their index args through `Namespace.add_namespace_to_index/2`. The low-level `Snap.Cluster.{get,post,...}` calls do **not** namespace — they're raw passthrough.

- **Config namespace** (`index_namespace: "app-dev"`): applied to every operation through the cluster. Used to separate apps/envs sharing one ES instance.
- **Process namespace** (`Namespace.set_process_namespace/2`): per-process prefix layered on top, looked up via `ProcessTree` so spawned child processes (e.g. LiveViews under test) inherit it. This is how `Snap.Test` achieves Ecto-Sandbox-style isolation for `async: true` tests.

### Testing infrastructure

- `test/test_helper.exs` starts `Snap.Test.Cluster` once with `index_namespace: "snap-test"` and excludes `:integration`-tagged tests by default.
- `Snap.IntegrationCase` (in `test/support`) generates a unique per-test process namespace, drops indexes before, and re-applies the namespace + drops indexes in `on_exit` (which runs in a separate process — the namespace has to be reset there).
- `Snap.Test.Cluster.handle_event/4` attaches a telemetry handler that pulls a per-test callback out of the process dictionary key `:telemetry`, so tests can assert against the telemetry payload by stashing a function before the request.

## Conventions

- Library functions return `{:ok, _} | {:error, exception}` — they do not raise for validation failures (see existing exceptions in `lib/snap/exceptions/`).
