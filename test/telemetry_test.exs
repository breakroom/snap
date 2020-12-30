defmodule Snap.TelemetryTest do
  use ExUnit.Case

  alias Snap.Test.Cluster

  test "telemetry is fired with a request" do
    log = fn event_name, measurements, metadata ->
      assert event_name == [:snap, :snap, :request]
      assert %{result: {:ok, _}, method: "GET", path: "/_cluster/health", body: nil} = metadata

      assert measurements.total_time ==
               measurements.query_time + measurements.decode_time + measurements.queue_time

      send(self(), :logged)
    end

    Process.put(:telemetry, log)
    _ = Snap.get(Cluster, "/_cluster/health")
    assert_received :logged
  end
end
