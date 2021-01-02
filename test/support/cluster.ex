defmodule Snap.Test.Cluster do
  @moduledoc false
  use Snap.Cluster, otp_app: :snap

  def init(config) do
    fun = &Snap.Test.Cluster.handle_event/4

    :telemetry.attach(__MODULE__, [:snap, :snap, :request], fun, :ok)

    {:ok, config}
  end

  def handle_event(event, latency, metadata, _config) do
    handler = Process.delete(:telemetry) || fn _, _, _ -> :ok end
    handler.(event, latency, metadata)
  end
end
