defmodule ElasticsearcherTest do
  use ExUnit.Case

  alias Snap.Test.Cluster

  test "getting server status" do
    {:ok, %{"status" => status}} = Snap.get(Cluster, "/_cluster/health")
    assert not is_nil(status)
  end

  test "deleting a missing index" do
    {:error, exception} = Snap.delete(Cluster, "/missing-index")
    assert exception.status == 404
    assert exception.type == "index_not_found_exception"
  end

  test "getting config" do
    %{url: url} = Cluster.config()
    assert url == "http://localhost:9200"
  end
end
