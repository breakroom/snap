defmodule Snap.ScrollTest do
  @moduledoc false
  use Snap.IntegrationCase, async: true

  alias Snap.Bulk.Action
  alias Snap.Scroll
  alias Snap.Test.Cluster

  @test_index "scroll"

  test "stream/4 yields every hit across multiple scroll batches" do
    {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

    1..7
    |> Enum.map(fn i -> %Action.Index{id: i, doc: %{"n" => i}} end)
    |> Snap.Bulk.perform(Cluster, @test_index, refresh: true)

    query = %{"query" => %{"match_all" => %{}}, "size" => 2, "sort" => ["_doc"]}

    hits = Scroll.stream(Cluster, @test_index, query) |> Enum.to_list()

    assert length(hits) == 7
    assert Enum.map(hits, & &1.id) == ~w(1 2 3 4 5 6 7)
  end

  test "stream/4 calls clear_scroll when the consumer halts early" do
    {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

    1..10
    |> Enum.map(fn i -> %Action.Index{id: i, doc: %{"n" => i}} end)
    |> Snap.Bulk.perform(Cluster, @test_index, refresh: true)

    parent = self()
    handler_id = {__MODULE__, :clear_scroll_observer, make_ref()}

    :telemetry.attach(
      handler_id,
      [:snap, :snap, :request],
      fn _event, _measurements, metadata, _config ->
        send(parent, {:request, metadata.method, metadata.path})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    query = %{"query" => %{"match_all" => %{}}, "size" => 2, "sort" => ["_doc"]}

    hits = Scroll.stream(Cluster, @test_index, query) |> Enum.take(3)

    assert length(hits) == 3
    assert_receive {:request, "DELETE", "/_search/scroll/" <> _}, 1_000
  end

  test "stream/4 returns an empty stream when nothing matches" do
    {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})
    :ok = Snap.Indexes.refresh(Cluster, @test_index)

    query = %{"query" => %{"match_all" => %{}}, "size" => 2}

    assert [] = Scroll.stream(Cluster, @test_index, query) |> Enum.to_list()
  end

  test "stream/4 raises if the initial search fails" do
    query = %{"query" => %{"this_is_not_a_real_query" => %{}}}

    assert_raise Snap.ResponseError, fn ->
      Scroll.stream(Cluster, @test_index, query) |> Enum.to_list()
    end
  end
end
