defmodule Snap.Bulk.Action.Create do
  @moduledoc """
  Represents a create step in a `Snap.Bulk` operation
  """
  @enforce_keys [:doc]
  defstruct [:_index, :_id, :require_alias, :doc]

  @type t :: %__MODULE__{
          _index: String.t() | nil,
          _id: String.t() | nil,
          require_alias: boolean() | nil,
          doc: map()
        }
end

defmodule Snap.Bulk.Action.Delete do
  @moduledoc """
  Represents a delete step in a `Snap.Bulk` operation
  """
  @enforce_keys [:_id]
  defstruct [:_index, :_id, :require_alias]

  @type t :: %__MODULE__{
          _index: String.t() | nil,
          _id: String.t(),
          require_alias: boolean() | nil
        }
end

defmodule Snap.Bulk.Action.Index do
  @moduledoc """
  Represents an index step in a `Snap.Bulk` operation
  """
  @enforce_keys [:doc]
  defstruct [:_index, :_id, :require_alias, :doc]

  @type t :: %__MODULE__{
          _index: String.t() | nil,
          _id: String.t() | nil,
          require_alias: boolean() | nil,
          doc: map()
        }
end

defmodule Snap.Bulk.Action.Update do
  @moduledoc """
  Represents an update step in a `Snap.Bulk` operation
  """
  @enforce_keys [:doc]
  defstruct [:_index, :_id, :require_alias, :doc]

  @type t :: %__MODULE__{
          _index: String.t() | nil,
          _id: String.t() | nil,
          require_alias: boolean() | nil,
          doc: map()
        }
end
