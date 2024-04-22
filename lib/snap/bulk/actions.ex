defmodule Snap.Bulk.Actions do
  @moduledoc false

  @doc """
  Encodes a list of bulk action structs into line separated JSON for feeding to the
  /_bulk endpoint.
  """
  def encode(actions, json_library \\ Jason) do
    encode_actions([], actions, json_library)
  end

  defp encode_actions(iolist, [], _json_library) do
    iolist
  end

  defp encode_actions(iolist, [head | tail], json_library) do
    updated_iolist = [iolist, encode_action(head, json_library)]
    encode_actions(updated_iolist, tail, json_library)
  end

  defp encode_action(%type{} = action, json_library) do
    action_json = type.to_action_json(action)
    doc_json = type.to_document_json(action)

    if doc_json do
      [encode_json(action_json, json_library), "\n", encode_json(doc_json, json_library), "\n"]
    else
      [encode_json(action_json, json_library), "\n"]
    end
  end

  defp encode_json(json, json_library) do
    json_library.encode!(json)
  end
end
