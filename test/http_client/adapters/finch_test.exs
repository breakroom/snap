defmodule Snap.HTTPClient.Adapters.FinchTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Snap.HTTPClient.Adapters.Finch, as: FinchAdapter
  alias Snap.HTTPClient.Error
  alias Snap.HTTPClient.Response

  describe "child_spec/1" do
    test "should set the default values for pool config" do
      config = build_config()

      assert {Finch,
              [
                name: Snap.Test.Cluster.Pool,
                pools: %{
                  "http://localhost:9200" => [
                    size: 5,
                    count: 1,
                    conn_opts: [],
                    start_pool_metrics?: true
                  ]
                }
              ]} == FinchAdapter.child_spec(config)
    end

    test "should be able to configure pool_size" do
      config = build_config(pool_size: 99)

      assert {Finch, received_finch_config} = FinchAdapter.child_spec(config)
      assert 99 == received_finch_config[:pools]["http://localhost:9200"][:size]
    end

    test "should be able to configure conn_opts" do
      config = build_config(conn_opts: [hostname: "test.hostname.com"])

      assert {Finch, received_finch_config} = FinchAdapter.child_spec(config)

      assert [hostname: "test.hostname.com"] ==
               received_finch_config[:pools]["http://localhost:9200"][:conn_opts]
    end

    test "should raise if cluster is not provided" do
      config = build_config() |> Keyword.delete(:cluster)

      expected_message = ~s(key :cluster not found in: [url: "http://localhost:9200"])
      assert_raise(KeyError, expected_message, fn -> FinchAdapter.child_spec(config) end)
    end

    test "should raise if url is not provided" do
      config = build_config() |> Keyword.delete(:url)

      expected_message = ~s(key :url not found in: [cluster: Snap.Test.Cluster])
      assert_raise(KeyError, expected_message, fn -> FinchAdapter.child_spec(config) end)
    end
  end

  describe "request/5" do
    @describetag :integration

    test "should return ok with status 200 when request is successful" do
      cluster = Snap.Test.Cluster
      method = :get
      url = "http://localhost:9200/_cluster/health"
      headers = []
      body = nil

      assert {:ok, %Response{} = response} =
               FinchAdapter.request(cluster, method, url, headers, body)

      assert 200 == response.status
      assert is_list(response.headers)
      assert is_binary(response.body)
    end

    test "should return ok with client error status if request is wrong" do
      cluster = Snap.Test.Cluster
      method = :get
      url = "http://localhost:9200/wrong-path"
      headers = []
      body = nil

      assert {:ok, %Response{} = response} =
               FinchAdapter.request(cluster, method, url, headers, body)

      assert 404 == response.status
      assert is_list(response.headers)
      assert is_binary(response.body)
    end

    test "should return error if request fails" do
      cluster = Snap.Test.Cluster
      method = :get
      url = "http://localhost:9999/wrong-port"
      headers = []
      body = nil

      assert {:error, %Error{} = error} =
               FinchAdapter.request(cluster, method, url, headers, body)

      assert %Error{
               reason: :econnrefused,
               origin: %Mint.TransportError{reason: :econnrefused}
             } == error
    end
  end

  test "should be able to retreive Finch pool metrics" do
    assert {:ok, [%Finch.HTTP1.PoolMetrics{}]} =
             Finch.get_pool_status(Snap.Test.Cluster.Pool, {:http, "localhost", 9200})
  end

  defp build_config(extra_config \\ []) do
    default_config = [
      cluster: Snap.Test.Cluster,
      url: "http://localhost:9200"
    ]

    Keyword.merge(default_config, extra_config)
  end
end
