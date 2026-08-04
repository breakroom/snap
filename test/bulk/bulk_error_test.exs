defmodule Snap.BulkErrorTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Snap.Bulk
  alias Snap.Bulk.Action
  alias Snap.Test.Cluster

  describe "perform/4" do
    test "collects non-response errors into the BulkError" do
      actions = [%Action.Index{id: 1, doc: %{foo: "bar"}}]

      assert {:error, %Snap.BulkError{errors: [%Snap.InvalidPathError{}]}} =
               Bulk.perform(actions, Cluster, "../..")
    end
  end
end
