defmodule Snap.Cluster do
  @moduledoc """
  Defines a cluster.

  A cluster maps to an Elasticsearch endpoint.

  When used, the cluster expects :otp_app as an option. The :otp_app should
  point to an OTP application that has the cluster configuration. For
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
    pool_size: 10
  ```
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

      def otp_app() do
        unquote(opts[:otp_app])
      end

      def get(path, params \\ [], headers \\ [], opts \\ []) do
        Request.request(__MODULE__, "GET", path, nil, params, headers, opts)
      end

      def post(path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
        Request.request(__MODULE__, "POST", path, body, params, headers, opts)
      end

      def put(path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
        Request.request(__MODULE__, "PUT", path, body, params, headers, opts)
      end

      def delete(path, params \\ [], headers \\ [], opts \\ []) do
        Request.request(__MODULE__, "DELETE", path, nil, params, headers, opts)
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
end
