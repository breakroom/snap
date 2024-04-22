defmodule Snap.BulkTest do
  @moduledoc false
  use Snap.IntegrationCase, async: true

  alias Snap
  alias Snap.Bulk
  alias Snap.Bulk.Action
  alias Snap.Test.Cluster

  @test_index "bulk"

  describe "perform/4" do
    test "running actions in 2 chunks with no errors" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      doc = %{foo: "bar"}

      actions = [
        %Action.Index{doc: doc, id: 1},
        %Action.Index{doc: doc, id: 2},
        %Action.Delete{id: 1},
        %Action.Delete{id: 2}
      ]

      result =
        actions
        |> Bulk.perform(Cluster, @test_index, page_size: 2, page_wait: 10)

      assert result == :ok
    end

    test "running actions in 2 chunks with errors in both chunks" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      doc = %{foo: "bar"}

      actions = [
        %Action.Index{doc: doc, id: 1},
        %Action.Update{doc: doc, id: 2},
        %Action.Update{doc: doc, id: 3},
        %Action.Update{doc: doc, id: 4}
      ]

      {:error, %Snap.BulkError{errors: errors}} =
        actions
        |> Bulk.perform(Cluster, @test_index, page_size: 2, page_wait: 10)

      assert Enum.count(errors) == 3

      error = Enum.at(errors, 0)

      assert error.status == 404
    end

    test "running actions in 2 chunks with max_errors count that gets exceeded in the first chunk" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      doc = %{foo: "bar"}

      actions = [
        %Action.Update{id: 1, doc: doc},
        %Action.Update{id: 2, doc: doc},
        %Action.Update{id: 3, doc: doc},
        %Action.Update{id: 4, doc: doc}
      ]

      {:error, %Snap.BulkError{errors: errors}} =
        actions
        |> Bulk.perform(Cluster, @test_index, page_size: 2, page_wait: 10, max_errors: 2)

      assert Enum.count(errors) == 4
    end

    test "running actions in 3 chunks with max_errors count that gets exceeded in the second chunk" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      doc = %{foo: "bar"}

      actions = [
        %Action.Update{id: 1, doc: doc},
        %Action.Update{id: 2, doc: doc},
        %Action.Update{id: 3, doc: doc},
        %Action.Update{id: 4, doc: doc},
        %Action.Update{id: 5, doc: doc},
        %Action.Update{id: 6, doc: doc}
      ]

      {:error, %Snap.BulkError{errors: errors}} =
        actions
        |> Bulk.perform(Cluster, @test_index, page_size: 2, page_wait: 10, max_errors: 3)

      assert Enum.count(errors) == 4
    end

    test "running actions in 2 chunks with a 0 max_errors count that never gets exceeded" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      doc = %{foo: "bar"}

      actions = [
        %Action.Index{id: 1, doc: doc},
        %Action.Index{id: 2, doc: doc},
        %Action.Index{id: 3, doc: doc},
        %Action.Index{id: 4, doc: doc},
        %Action.Index{id: 5, doc: doc},
        %Action.Index{id: 6, doc: doc}
      ]

      assert :ok ==
               actions
               |> Bulk.perform(Cluster, @test_index, page_size: 2, page_wait: 10, max_errors: 0)
    end
  end
end
