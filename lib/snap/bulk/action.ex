defmodule Snap.Bulk.Action do
  @moduledoc false
  @callback to_action_json(struct()) :: map()
  @callback to_document_json(struct()) :: map() | nil

  @typedoc """
  The version type used for optimistic concurrency control.
  """
  @type version_type :: :internal | :external | :external_gte | String.t()

  @typedoc """
  Controls which parts of the document `_source` are returned for an action.

  Either a boolean, a wildcard string, a list of wildcard strings, or a map of
  `includes` and `excludes`.
  """
  @type source :: boolean() | String.t() | [String.t()] | map()

  @doc false
  def compact(values) do
    values
    |> Enum.reject(&is_nil(elem(&1, 1)))
    |> Enum.into(%{})
  end
end

defmodule Snap.Bulk.Action.Create do
  @moduledoc """
  Represents a create step in a `Snap.Bulk` operation.

  Creates a document if it does not already exist, returning an error
  otherwise.

  Supports the following fields:

  * `doc` - the document to index (required)
  * `index` - the index to write to, if not specified on the bulk operation
  * `id` - the document ID. Elasticsearch generates one if it is omitted
  * `require_alias` - when `true`, the destination must be an index alias
  * `routing` - the custom routing value for the document
  * `version` - the explicit version number, for optimistic concurrency control
  * `version_type` - one of `:internal`, `:external` or `:external_gte`
  * `if_seq_no` - only perform the action if the document has this sequence
    number
  * `if_primary_term` - only perform the action if the document has this
    primary term
  * `pipeline` - the ingest pipeline to run the document through
  """
  @behaviour Snap.Bulk.Action

  alias Snap.Bulk.Action

  @enforce_keys [:doc]
  defstruct [
    :index,
    :id,
    :require_alias,
    :doc,
    :routing,
    :version,
    :version_type,
    :if_seq_no,
    :if_primary_term,
    :pipeline
  ]

  @type t :: %__MODULE__{
          index: String.t() | nil,
          id: String.t() | nil,
          require_alias: boolean() | nil,
          doc: map(),
          routing: String.t() | nil,
          version: integer() | nil,
          version_type: Action.version_type() | nil,
          if_seq_no: integer() | nil,
          if_primary_term: integer() | nil,
          pipeline: String.t() | nil
        }

  @doc false
  def to_action_json(%__MODULE__{} = action) do
    %{
      _index: action.index,
      _id: action.id,
      require_alias: action.require_alias,
      routing: action.routing,
      version: action.version,
      version_type: action.version_type,
      if_seq_no: action.if_seq_no,
      if_primary_term: action.if_primary_term,
      pipeline: action.pipeline
    }
    |> Action.compact()
    |> then(fn values -> %{"create" => values} end)
  end

  @doc false
  def to_document_json(%__MODULE__{doc: doc}) do
    doc
  end
end

defmodule Snap.Bulk.Action.Delete do
  @moduledoc """
  Represents a delete step in a `Snap.Bulk` operation.

  Supports the following fields:

  * `id` - the document ID to delete (required)
  * `index` - the index to delete from, if not specified on the bulk operation
  * `require_alias` - when `true`, the destination must be an index alias
  * `routing` - the custom routing value for the document
  * `version` - the explicit version number, for optimistic concurrency control
  * `version_type` - one of `:internal`, `:external` or `:external_gte`
  * `if_seq_no` - only perform the action if the document has this sequence
    number
  * `if_primary_term` - only perform the action if the document has this
    primary term
  """
  @behaviour Snap.Bulk.Action

  alias Snap.Bulk.Action

  @enforce_keys [:id]
  defstruct [
    :index,
    :id,
    :require_alias,
    :routing,
    :version,
    :version_type,
    :if_seq_no,
    :if_primary_term
  ]

  @type t :: %__MODULE__{
          index: String.t() | nil,
          id: String.t(),
          require_alias: boolean() | nil,
          routing: String.t() | nil,
          version: integer() | nil,
          version_type: Action.version_type() | nil,
          if_seq_no: integer() | nil,
          if_primary_term: integer() | nil
        }

  @doc false
  def to_action_json(%__MODULE__{} = action) do
    %{
      _index: action.index,
      _id: action.id,
      require_alias: action.require_alias,
      routing: action.routing,
      version: action.version,
      version_type: action.version_type,
      if_seq_no: action.if_seq_no,
      if_primary_term: action.if_primary_term
    }
    |> Action.compact()
    |> then(fn values -> %{"delete" => values} end)
  end

  @doc false
  def to_document_json(_), do: nil
end

defmodule Snap.Bulk.Action.Index do
  @moduledoc """
  Represents an index step in a `Snap.Bulk` operation.

  Creates a document if it does not yet exist, and replaces it if it does.

  Supports the following fields:

  * `doc` - the document to index (required)
  * `index` - the index to write to, if not specified on the bulk operation
  * `id` - the document ID. Elasticsearch generates one if it is omitted
  * `require_alias` - when `true`, the destination must be an index alias
  * `routing` - the custom routing value for the document
  * `version` - the explicit version number, for optimistic concurrency control
  * `version_type` - one of `:internal`, `:external` or `:external_gte`
  * `if_seq_no` - only perform the action if the document has this sequence
    number
  * `if_primary_term` - only perform the action if the document has this
    primary term
  * `pipeline` - the ingest pipeline to run the document through
  """
  @behaviour Snap.Bulk.Action

  alias Snap.Bulk.Action

  @enforce_keys [:doc]
  defstruct [
    :index,
    :id,
    :require_alias,
    :doc,
    :routing,
    :version,
    :version_type,
    :if_seq_no,
    :if_primary_term,
    :pipeline
  ]

  @type t :: %__MODULE__{
          index: String.t() | nil,
          id: String.t() | nil,
          require_alias: boolean() | nil,
          doc: map(),
          routing: String.t() | nil,
          version: integer() | nil,
          version_type: Action.version_type() | nil,
          if_seq_no: integer() | nil,
          if_primary_term: integer() | nil,
          pipeline: String.t() | nil
        }

  @doc false
  def to_action_json(%__MODULE__{} = action) do
    %{
      _index: action.index,
      _id: action.id,
      require_alias: action.require_alias,
      routing: action.routing,
      version: action.version,
      version_type: action.version_type,
      if_seq_no: action.if_seq_no,
      if_primary_term: action.if_primary_term,
      pipeline: action.pipeline
    }
    |> Action.compact()
    |> then(fn values -> %{"index" => values} end)
  end

  @doc false
  def to_document_json(%__MODULE__{doc: doc}) do
    doc
  end
end

defmodule Snap.Bulk.Action.Update do
  @moduledoc """
  Represents an update step in a `Snap.Bulk` operation.

  Updates an existing document, returning an error if it does not exist,
  unless an upsert is configured.

  Supports the following action fields:

  * `index` - the index to write to, if not specified on the bulk operation
  * `id` - the document ID to update
  * `require_alias` - when `true`, the destination must be an index alias
  * `routing` - the custom routing value for the document
  * `if_seq_no` - only perform the action if the document has this sequence
    number
  * `if_primary_term` - only perform the action if the document has this
    primary term
  * `retry_on_conflict` - how many times to retry the update if a version
    conflict occurs
  * `pipeline` - the ingest pipeline to run an upserted document through
  * `source` - which parts of the updated `_source` to return

  Note that updates do not support `version`/`version_type`. Use `if_seq_no`
  and `if_primary_term` instead.

  Along with the following document fields:

  * `doc` - the partial document to merge into the existing one
  * `doc_as_upsert` - when `true`, `doc` is indexed if the document does not
    already exist
  * `script` - a script to run against the existing document, instead of `doc`
  * `upsert` - the document to index if it does not already exist
  * `scripted_upsert` - when `true`, `script` is run against `upsert` when the
    document does not already exist
  * `detect_noop` - when `false`, the document is always reindexed, even if
    `doc` makes no changes to it
  """
  @behaviour Snap.Bulk.Action

  alias Snap.Bulk.Action

  defstruct [
    :id,
    :index,
    :require_alias,
    :doc,
    :doc_as_upsert,
    :script,
    :upsert,
    :scripted_upsert,
    :detect_noop,
    :routing,
    :if_seq_no,
    :if_primary_term,
    :retry_on_conflict,
    :pipeline,
    :source
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          index: String.t() | nil,
          require_alias: boolean() | nil,
          doc: map() | nil,
          doc_as_upsert: boolean() | nil,
          script: map() | nil,
          upsert: map() | nil,
          scripted_upsert: boolean() | nil,
          detect_noop: boolean() | nil,
          routing: String.t() | nil,
          if_seq_no: integer() | nil,
          if_primary_term: integer() | nil,
          retry_on_conflict: integer() | nil,
          pipeline: String.t() | nil,
          source: Action.source() | nil
        }

  @doc false
  def to_action_json(%__MODULE__{} = action) do
    %{
      _index: action.index,
      _id: action.id,
      require_alias: action.require_alias,
      routing: action.routing,
      if_seq_no: action.if_seq_no,
      if_primary_term: action.if_primary_term,
      retry_on_conflict: action.retry_on_conflict,
      pipeline: action.pipeline,
      _source: action.source
    }
    |> Action.compact()
    |> then(fn values -> %{"update" => values} end)
  end

  @doc false
  def to_document_json(%__MODULE__{} = action) do
    %{
      doc: action.doc,
      doc_as_upsert: action.doc_as_upsert,
      script: action.script,
      upsert: action.upsert,
      scripted_upsert: action.scripted_upsert,
      detect_noop: action.detect_noop
    }
    |> Action.compact()
  end
end
