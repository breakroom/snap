defmodule Snap.BulkTest do
  use Snap.IntegrationCase

  alias Snap
  alias Snap.Bulk
  alias Snap.Bulk.Action
  alias Snap.Test.Cluster

  describe "perform/4" do
    test "running actions in 2 chunks with no errors" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      doc = %{foo: "bar"}

      actions = [
        %Action.Index{doc: doc, _id: 1},
        %Action.Index{doc: doc, _id: 2},
        %Action.Delete{_id: 1},
        %Action.Delete{_id: 2}
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
        %Action.Index{doc: doc, _id: 1},
        %Action.Update{doc: doc, _id: 2},
        %Action.Update{doc: doc, _id: 3},
        %Action.Update{doc: doc, _id: 4}
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
        %Action.Update{_id: 1, doc: doc},
        %Action.Update{_id: 2, doc: doc},
        %Action.Update{_id: 3, doc: doc},
        %Action.Update{_id: 4, doc: doc}
      ]

      {:error, %Snap.BulkError{errors: errors}} =
        actions
        |> Bulk.perform(Cluster, @test_index, page_size: 2, page_wait: 10, max_errors: 2)

      assert Enum.count(errors) == 2

      error = Enum.at(errors, 0)

      assert error.status == 404
    end
  end
end
