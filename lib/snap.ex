defmodule Snap do
  @moduledoc """
  Snap is split into a few key modules:

  * `Snap.Cluster` - clusters are wrappers around the Elasticsearch HTTP API.
    We use these to perform low-level HTTP requests.

  * `Snap.Indexes` - a convenience wrapper around the Elasticsearch indexes
    APIs, allowing the creation, deleting and aliasing of indexes, along with
    hotswap functionality to bulk load documents into an aliased index,
    switching to it atomically.

  * `Snap.Document` - a convenience wrapper around the Document APIs, allowing
    the creating, updating and deleting individual documents.

  * `Snap.Search` - for performing searches

  * `Snap.Multi` - for performing multiple searches in a single query

  * `Snap.Bulk` - a convenience wrapper around bulk operations, using `Stream`
    to stream actions (such as `Snap.Bulk.Action.Create`) to be performed
    against the `Snap.Cluster`.

  Additionally, there are other supporting modules:

  * `Snap.HTTPClient` - defines how to send HTTP requests.
    Comes with a built in adapter for `Finch` (`Snap.HTTPClient.Adapters.Finch`)

  * `Snap.Auth` - defines how an HTTP request is modified to include
    authentication headers. `Snap.Auth.Plain` implements HTTP Basic Auth.

  * `Snap.Cluster.Namespace` - for isolating cluster and processes to work on
    separate indexes

  ## Set up

  `Snap.Cluster` is a wrapped around an Elasticsearch cluster. We can define
  it like so:

  ```
  defmodule MyApp.Cluster do
    use Snap.Cluster, otp_app: :my_app
  end
  ```

  The configuration for the cluster can be defined in your config:

  ```
  config :my_app, MyApp.Cluster,
    url: "http://localhost:9200",
    username: "username",
    password: "password"
  ```

  Or you can load it dynamically by implementing `c:Snap.Cluster.init/1`.

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

  ## Config

  The following configuration options are supported:

  * `url` - the URL of the Elasticsearch HTTP endpoint (required)
  * `username` - the username used to access the cluster
  * `password` - the password used to access the cluster
  * `auth` - the auth module used to configure the HTTP authentication headers
    (defaults to `Snap.Auth.Plain`)
  * `http_client_adapter` - the adapter that will be used to send HTTP requests.
    Check `Snap.HTTPClient` for more information.
    (defaults to `Snap.HTTPClient.Adapters.Finch`)
  * `telemetry_prefix` - the prefix of the telemetry events (defaults to
    `[:my_app, :snap]`)
  * `index_namespace` - see `Snap.Cluster.Namespace` for details (defaults to
    `nil`)
  * `json_library` - the library used for encoding/decoding JSON (defaults to
    `Jason`. You may wish to switch this to [`Jsonrs`](https://hex.pm/packages/jsonrs)
     for better performance encoding and decoding large requests and responses)

  ## Telemetry

  Snap supports sending `Telemetry` events on each HTTP request. It sends one
  event per query, of the name `[:my_app, :snap, :request]`.

  The telemetry event has the following measurements:

  * `response_time` - how long the request took to return
  * `decode_time` - how long the response took to decode into a map or
    exception
  * `total_time` - how long everything took in total
  * `request_body_bytes` - the count of bytes in the request body
  * `response_body_bytes` - the count of bytes in the response body

  In addition, the metadata contains a map of:

  * `method` - the HTTP method used
  * `path` - the path requested
  * `port` - the port requested
  * `host` - the host requested
  * `headers` - a list of the headers sent
  * `body` - the body sent
  * `result` - the result returned to the user
  * `status` - the HTTP status code of the response

  ## Testing

  See `Snap.Test` for details.
  """

  alias Snap.Request

  @doc false
  def get(cluster, path, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, :get, path, nil, params, headers, opts)
  end

  @doc false
  def post(cluster, path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, :post, path, body, params, headers, opts)
  end

  @doc false
  def put(cluster, path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, :put, path, body, params, headers, opts)
  end

  @doc false
  def delete(cluster, path, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, :delete, path, nil, params, headers, opts)
  end
end
