defmodule SnapTest do
  use ExUnit.Case, async: true

  alias Snap.Test.Cluster

  @tag :integration
  test "getting server status" do
    {:ok, %{"status" => status}} = Snap.get(Cluster, "/_cluster/health")
    assert not is_nil(status)
  end

  test "getting config" do
    url = Cluster.config() |> Keyword.fetch!(:url)
    assert url == "http://localhost:9200"
  end

  test "getting otp_app" do
    assert :snap == Cluster.otp_app()
  end
end
