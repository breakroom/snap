defmodule Snap.MultiTest do
  use Snap.IntegrationCase

  alias Snap.Bulk.Action
  alias Snap.Multi
  alias Snap.Test.Cluster

  setup_all do
    {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

    1..5
    |> Enum.map(fn i ->
      doc = %{"title" => "Document #{i}"}

      %Action.Index{_id: i, doc: doc}
    end)
    |> Snap.Bulk.perform(Cluster, @test_index, refresh: :wait_for)
  end

  test "simple multi search" do
    {:ok, %Multi.Response{} = response} =
      Multi.new()
      |> Multi.add(%{query: %{query_string: %{query: "Document 1"}}})
      |> Multi.add(%{query: %{query_string: %{query: "Document 2"}}})
      |> Multi.run(Cluster, @test_index)

    assert length(response.searches) == 2
  end

  test "multi search with headers" do
    {:ok, %Multi.Response{} = response} =
      Multi.new()
      |> Multi.add(%{query: %{query_string: %{query: "Document 1"}}}, request_cache: false)
      |> Multi.add(%{query: %{query_string: %{query: "Document 2"}}})
      |> Multi.run(Cluster, @test_index)

    assert length(response.searches) == 2
  end

  test "multi search with named queries" do
    {:ok, %Multi.Response{} = response} =
      Multi.new()
      |> Multi.add(%{query: %{query_string: %{query: "Document 1"}}}, id: "foo")
      |> Multi.add(%{query: %{query_string: %{query: "Document 2"}}}, id: "bar")
      |> Multi.run(Cluster, @test_index)

    assert length(response.searches) == 2

    searches_map = Enum.into(response.searches, %{})

    assert Map.has_key?(searches_map, "foo")
    assert Map.has_key?(searches_map, "bar")
  end
end
