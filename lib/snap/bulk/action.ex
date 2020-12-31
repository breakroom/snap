defmodule Snap.Bulk.Action.Create do
  @enforce_keys [:doc]
  defstruct [:_index, :_id, :require_alias, :doc]
end

defmodule Snap.Bulk.Action.Delete do
  @enforce_keys [:_id]
  defstruct [:_index, :_id, :require_alias]
end

defmodule Snap.Bulk.Action.Index do
  @enforce_keys [:doc]
  defstruct [:_index, :_id, :require_alias, :doc]
end

defmodule Snap.Bulk.Action.Update do
  @enforce_keys [:doc]
  defstruct [:_index, :_id, :require_alias, :doc]
end
