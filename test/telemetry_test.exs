defmodule Snap.TelemetryTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Snap.Test.Cluster

  @tag :integration
  test "telemetry is fired with a request" do
    log = fn event_name, measurements, metadata ->
      assert event_name == [:snap, :snap, :request]

      assert %{
               result: {:ok, _},
               method: "GET",
               path: "/_cluster/health",
               host: "localhost",
               port: 9200,
               body: nil,
               status: 200
             } = metadata

      assert measurements.total_time ==
               measurements.response_time + measurements.decode_time

      send(self(), :logged)
    end

    Process.put(:telemetry, log)
    _ = Snap.get(Cluster, "/_cluster/health")
    assert_received :logged
  end
end
