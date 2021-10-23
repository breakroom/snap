defmodule Snap.Dev.Cluster do
  @moduledoc false
  use Snap.Cluster, otp_app: :snap
end

Logger.configure(level: :debug)

Task.start(fn ->
  children = [
    {Snap.Dev.Cluster, [url: "http://localhost:9200"]},
  ]

  {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
  Process.sleep(:infinity)
end)
