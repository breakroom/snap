defmodule Snap.Bulk.ActionsTest do
  use ExUnit.Case, async: true

  alias Snap.Bulk.Action
  alias Snap.Bulk.Actions

  test "encoding actions" do
    doc = %{foo: "bar"}

    actions = [
      %Action.Index{_index: "foo", doc: doc},
      %Action.Create{_index: "foo", doc: doc, require_alias: true},
      %Action.Update{_index: "foo", doc: doc, _id: 2},
      %Action.Delete{_index: "foo", _id: 1}
    ]

    encoded = Actions.encode(actions) |> IO.chardata_to_string()

    assert encoded ==
             "{\"index\":{\"_index\":\"foo\"}}\n{\"foo\":\"bar\"}\n{\"create\":{\"_index\":\"foo\",\"require_alias\":true}}\n{\"foo\":\"bar\"}\n{\"update\":{\"_index\":\"foo\",\"_id\":2}}\n{\"doc\":{\"foo\":\"bar\"}}\n{\"delete\":{\"_index\":\"foo\",\"_id\":1}}\n"
  end
end
