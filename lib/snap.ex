defmodule Snap do
  @moduledoc """
  Snap is split into 3 main components:

  * `Snap.Cluster` - clusters are wrappers around the Elasticsearch HTTP API.
    We can use this to perform low-level HTTP requests.

  * `Snap.Bulk` - a convenience wrapper around bulk operations, using `Stream`
    to stream actions (such as `Snap.Bulk.Action.Create`) to be performed
    against the `Snap.Cluster`.

  * `Snap.Indexes` - a convenience wrapped around Elasticsearch indexes,
    allowing the creation, deleting and aliasing of indexes, along with hotswap
    functionality to bulk load documents into an aliased index, switching to it
    atomically.

  Additionally, there are other supporting modules:

  * `Snap.Auth` - defines how an HTTP request is modified to include
    authentication headers. `Snap.Auth.Plain` implements HTTP Basic Auth.

  ## Clusters

  `Snap.Cluster` is a wrapped around an Elasticsearch cluster. We can define
  it like so:

  ```
  defmodule MyApp.Cluster do
    use Snap.Cluster, otp_app: :my_app
  end
  ```

  The configuration for the cluster is defined in your config:

  ```
  config :my_app, MyApp.Cluster,
    url: "http://localhost:9200",
    username: "username",
    password: "password"
  ```

  Each cluster defines `start_link/1` which must be invoked before using the
  cluster and optionally accepts an explicit config. It creates the
  supervision tree, including the connection pool.

  Include it in your application:

  ```
  def start(_type, _args) do
    children = [
      {MyApp.Cluster, []}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
  ```
  """

  alias Snap.Request

  @doc false
  def get(cluster, path, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, "GET", path, nil, params, headers, opts)
  end

  @doc false
  def post(cluster, path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, "POST", path, body, params, headers, opts)
  end

  @doc false
  def put(cluster, path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, "PUT", path, body, params, headers, opts)
  end

  @doc false
  def delete(cluster, path, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, "DELETE", path, nil, params, headers, opts)
  end
end
