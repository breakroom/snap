defmodule Snap.Cluster do
  @moduledoc """
  Defines a cluster.

  A cluster maps to an Elasticsearch endpoint.

  When used, the cluster expects `:otp_app` as an option. The `:otp_app`
  should point to an OTP application that has the cluster configuration. For
  example, this cluster:

  ```
  defmodule MyApp.Cluster do
    use Snap.Cluster, otp_app: :my_app
  end
  ```

  Can be configured with:

  ```
  config :my_app, MyApp.Cluster,
    url: "http://localhost:9200",
    username: "username",
    password: "password",
    index_namespace: "app-dev"
  ```

  For details about how index namespacing works, see `Snap.Cluster.Namespace`.
  """
  defmacro __using__(opts) do
    quote do
      alias Snap.Cluster.Supervisor
      alias Snap.Request

      def init(config) do
        {:ok, config}
      end

      defoverridable init: 1

      @doc """
      Returns the config map that the Cluster was defined with.
      """
      def config() do
        Supervisor.config(__MODULE__)
      end

      @doc """
      Returns the otp_app that the Cluster was defined with.
      """
      def otp_app() do
        unquote(opts[:otp_app])
      end

      def get(path, params \\ [], headers \\ [], opts \\ []) do
        Request.request(__MODULE__, :get, path, nil, params, headers, opts)
      end

      def post(path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
        Request.request(__MODULE__, :post, path, body, params, headers, opts)
      end

      def put(path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
        Request.request(__MODULE__, :put, path, body, params, headers, opts)
      end

      def delete(path, params \\ [], headers \\ [], opts \\ []) do
        Request.request(__MODULE__, :delete, path, nil, params, headers, opts)
      end

      def patch(path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
        Request.request(__MODULE__, :patch, path, body, params, headers, opts)
      end

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(config \\ []) do
        otp_app = unquote(opts[:otp_app])
        config = Application.get_env(otp_app, __MODULE__, config)

        {:ok, config} = init(config)

        Supervisor.start_link(__MODULE__, otp_app, config)
      end
    end
  end

  @typedoc "The path of the HTTP endpoint"
  @type path :: String.t()

  @typedoc "The query params, which will be appended to the path"
  @type params :: Keyword.t()

  @typedoc "The body of the HTTP request"
  @type body :: String.t() | nil | binary() | map()

  @typedoc "Any additional HTTP headers sent with the request"
  @type headers :: Snap.HTTPClient.headers()

  @typedoc "Options passed through to the request"
  @type opts :: Keyword.t()

  @typedoc "The result from an HTTP operation"
  @type result :: success() | error()

  @typedoc "A successful results from an HTTP operation"
  @type success :: {:ok, map()}

  @typedoc "An error from an HTTP operation"
  @type error ::
          {:error, Snap.ResponseError.t() | Snap.HTTPClient.Error.t() | Jason.DecodeError.t()}

  @typedoc "Options available for configuring the Cluster"
  @type config_opts :: [
          url: String.t(),
          username: String.t(),
          password: String.t(),
          auth: Snap.Auth.t(),
          index_namespace: String.t() | nil,
          telemetry_prefix: list(atom()),
          http_client_adapter:
            Snap.HTTPClient.t() | {Snap.HTTPClient.t(), adapter_config :: Keyword.t()}
        ]

  @doc """
  Sends a GET request.

  Returns either:

  * `{:ok, response}` - where response is a map representing the parsed JSON response.
  * `{:error, error}` - where the error can be a struct of either:
    * `Snap.ResponseError`
    * `Snap.HTTPClient.Error`
    * `Jason.DecodeError`
  """
  @callback get(path, params, headers, opts) :: result()

  @doc """
  Sends a POST request.

  Returns either:

  * `{:ok, response}` - where response is a map representing the parsed JSON response.
  * `{:error, error}` - where the error can be a struct of either:
    * `Snap.ResponseError`
    * `Snap.HTTPClient.Error`
    * `Jason.DecodeError`
  """
  @callback post(path, body, params, headers, opts) :: result()

  @doc """
  Sends a PUT request.

  Returns either:

  * `{:ok, response}` - where response is a map representing the parsed JSON response.
  * `{:error, error}` - where the error can be a struct of either:
    * `Snap.ResponseError`
    * `Snap.HTTPClient.Error`
    * `Jason.DecodeError`
  """
  @callback put(path, body, params, headers, opts) :: result()

  @doc """
  Sends a DELETE request.

  Returns either:

  * `{:ok, response}` - where response is a map representing the parsed JSON response.
  * `{:error, error}` - where the error can be a struct of either:
    * `Snap.ResponseError`
    * `Snap.HTTPClient.Error`
    * `Jason.DecodeError`
  """
  @callback delete(path, params, headers, opts) :: result()

  @doc """
  Returns the config in use by this cluster.
  """
  @callback config() :: Keyword.t()

  @doc """
  Sets up the config for the cluster.

  Override this to dynamically load a config from somewhere other than your
  application config.
  """
  @callback init(Keyword.t() | nil) :: {:ok, Keyword.t()}
end
