defmodule ElasticsearcherTest do
  use ExUnit.Case

  alias Elasticsearcher.Test.Cluster

  test "getting server status" do
    {:ok, %{"status" => status}} = Elasticsearcher.get(Cluster, "/_cluster/health")
    assert not is_nil(status)
  end

  test "getting config" do
    %{url: url} = Cluster.config()
    assert url == "http://localhost:9200"
  end
end
