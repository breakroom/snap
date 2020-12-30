defmodule Snap.Cluster do
  defmacro __using__(opts) do
    quote do
      def init(config) do
        {:ok, config}
      end

      defoverridable init: 1

      def with_connection(fun) do
        Snap.Cluster.Supervisor.with_connection(__MODULE__, fun)
      end

      def config() do
        Snap.Cluster.Supervisor.config(__MODULE__)
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

        Snap.Cluster.Supervisor.start_link(__MODULE__, otp_app, config)
      end
    end
  end
end
