defmodule Snap.Bulk.Action do
  @moduledoc false
  @callback to_action_json(struct()) :: map()
  @callback to_document_json(struct()) :: map() | nil
end

defmodule Snap.Bulk.Action.Create do
  @moduledoc """
  Represents a create step in a `Snap.Bulk` operation
  """
  @behaviour Snap.Bulk.Action

  @enforce_keys [:doc]
  defstruct [:index, :id, :require_alias, :doc, :routing]

  @type t :: %__MODULE__{
          index: String.t() | nil,
          id: String.t() | nil,
          require_alias: boolean() | nil,
          doc: map(),
          routing: String.t() | nil
        }

  @doc false
  def to_action_json(%__MODULE__{
        index: index,
        id: id,
        require_alias: require_alias,
        routing: routing
      }) do
    values = %{_index: index, _id: id, require_alias: require_alias, routing: routing}

    values
    |> Enum.reject(&is_nil(elem(&1, 1)))
    |> Enum.into(%{})
    |> then(fn values -> %{"create" => values} end)
  end

  @doc false
  def to_document_json(%__MODULE__{doc: doc}) do
    doc
  end
end

defmodule Snap.Bulk.Action.Delete do
  @moduledoc """
  Represents a delete step in a `Snap.Bulk` operation
  """
  @behaviour Snap.Bulk.Action

  @enforce_keys [:id]
  defstruct [:index, :id, :require_alias, :routing]

  @type t :: %__MODULE__{
          index: String.t() | nil,
          id: String.t(),
          require_alias: boolean() | nil,
          routing: String.t() | nil
        }

  @doc false
  def to_action_json(%__MODULE__{
        index: index,
        id: id,
        require_alias: require_alias,
        routing: routing
      }) do
    values = %{_index: index, _id: id, require_alias: require_alias, routing: routing}

    values
    |> Enum.reject(&is_nil(elem(&1, 1)))
    |> Enum.into(%{})
    |> then(fn values -> %{"delete" => values} end)
  end

  @doc false
  def to_document_json(_), do: nil
end

defmodule Snap.Bulk.Action.Index do
  @moduledoc """
  Represents an index step in a `Snap.Bulk` operation
  """
  @behaviour Snap.Bulk.Action

  @enforce_keys [:doc]
  defstruct [:index, :id, :require_alias, :doc, :routing]

  @type t :: %__MODULE__{
          index: String.t() | nil,
          id: String.t() | nil,
          require_alias: boolean() | nil,
          doc: map(),
          routing: String.t() | nil
        }

  @doc false
  def to_action_json(%__MODULE__{
        index: index,
        id: id,
        require_alias: require_alias,
        routing: routing
      }) do
    values = %{_index: index, _id: id, require_alias: require_alias, routing: routing}

    values
    |> Enum.reject(&is_nil(elem(&1, 1)))
    |> Enum.into(%{})
    |> then(fn values -> %{"index" => values} end)
  end

  @doc false
  def to_document_json(%__MODULE__{doc: doc}) do
    doc
  end
end

defmodule Snap.Bulk.Action.Update do
  @moduledoc """
  Represents an update step in a `Snap.Bulk` operation
  """
  @behaviour Snap.Bulk.Action

  @enforce_keys [:doc]
  defstruct [
    :id,
    :index,
    :require_alias,
    :doc,
    :doc_as_upsert,
    :script,
    :routing
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          index: String.t() | nil,
          require_alias: boolean() | nil,
          doc: map(),
          doc_as_upsert: boolean() | nil,
          script: map() | nil,
          routing: String.t() | nil
        }

  @doc false
  def to_action_json(%__MODULE__{
        index: index,
        id: id,
        require_alias: require_alias,
        routing: routing
      }) do
    values = %{_index: index, _id: id, require_alias: require_alias, routing: routing}

    values
    |> Enum.reject(&is_nil(elem(&1, 1)))
    |> Enum.into(%{})
    |> then(fn values -> %{"update" => values} end)
  end

  @doc false
  def to_document_json(%__MODULE__{doc: doc, doc_as_upsert: doc_as_upsert, script: script}) do
    values = %{doc: doc, doc_as_upsert: doc_as_upsert, script: script}

    values
    |> Enum.reject(&is_nil(elem(&1, 1)))
    |> Enum.into(%{})
  end
end
