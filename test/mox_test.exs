defmodule Snap.MoxTest do
  use ExUnit.Case

  alias Snap.Test.Cluster

  import Mox

  setup :verify_on_exit!

  setup_all do
    :ok = GenServer.stop(Cluster)
    {:ok, _} = Cluster.start_link(
      url: "http://localhost:9200",
      http_client_adapter: HTTPClientMock,
      skip_initialize_http_client: true
    )

    on_exit(fn ->
      url = "http://localhost:9200"

      Cluster.start_link(url: url)
    end)
  end


  test "mox" do
    Mox.expect(HTTPClientMock, :request, fn _cluster, _method, _url, _headers, _body, _opts ->
      body = "{}" # valid json
      {:ok, %Snap.HTTPClient.Response{status: 200, headers: [], body: body}}
    end)

    assert {:ok, _} = Snap.get(Cluster, "/")
  end
end
