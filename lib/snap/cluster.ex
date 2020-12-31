defmodule Snap.Cluster do
  defmacro __using__(opts) do
    quote do
      alias Snap.Cluster.Supervisor

      def init(config) do
        {:ok, config}
      end

      defoverridable init: 1

      def request(method, path, headers, body \\ nil, opts \\ []) do
        pool_name = Supervisor.connection_pool_name(__MODULE__)
        config = Supervisor.config(__MODULE__)

        request_opts = Keyword.take(opts, [:pool_timeout, :receive_timeout])
        url_opts = Keyword.drop(opts, [:pool_timeout, :receive_timeout]) |> Enum.into(%{})

        root_url = Map.fetch!(config, :url)
        url = Snap.Request.assemble_url(root_url, path, url_opts)

        Finch.build(method, url, headers, body)
        |> Finch.request(pool_name, request_opts)
      end

      def config() do
        Supervisor.config(__MODULE__)
      end

      def otp_app() do
        unquote(opts[:otp_app])
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
