defmodule Snap.Bulk.ActionsTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Snap.Bulk.Action
  alias Snap.Bulk.Actions

  test "encoding actions" do
    doc = %{foo: "bar"}

    actions = [
      %Action.Index{_index: "foo", doc: doc, routing: "bar"},
      %Action.Create{_index: "foo", doc: doc, require_alias: true, routing: "bar"},
      %Action.Update{_index: "foo", doc: doc, _id: 2, routing: "bar"},
      %Action.Delete{_index: "foo", _id: 1, routing: "bar"}
    ]

    encoded = Actions.encode(actions) |> IO.chardata_to_string()

    assert encoded ==
             "{\"index\":{\"_index\":\"foo\",\"routing\":\"bar\"}}\n{\"foo\":\"bar\"}\n{\"create\":{\"_index\":\"foo\",\"require_alias\":true,\"routing\":\"bar\"}}\n{\"foo\":\"bar\"}\n{\"update\":{\"_index\":\"foo\",\"_id\":2,\"routing\":\"bar\"}}\n{\"doc\":{\"foo\":\"bar\"}}\n{\"delete\":{\"_index\":\"foo\",\"_id\":1,\"routing\":\"bar\"}}\n"
  end
end
