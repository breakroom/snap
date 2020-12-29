defmodule Elasticsearcher.Cluster do
  defmacro __using__(opts) do
    quote do
      def init(config) do
        {:ok, config}
      end

      defoverridable init: 1

      def with_connection(fun) do
        Elasticsearcher.Cluster.Supervisor.with_connection(__MODULE__, fun)
      end

      def config() do
        Elasticsearcher.Cluster.Supervisor.config(__MODULE__)
      end

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      def start_link(config \\ []) do
        otp_app = unquote(opts[:opt_app])
        config = Application.get_env(otp_app, __MODULE__, config)

        Elasticsearcher.Cluster.Supervisor.start_link(__MODULE__, otp_app, config)
      end
    end
  end
end
