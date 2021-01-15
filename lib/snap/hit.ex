defmodule Snap.Hit do
  @moduledoc """
  Represents an individual hit dictionary from a [Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html) response.
  """
  defstruct [:_index, :_type, :_id, :_score, :_source, :fields]

  def new(response) do
    %__MODULE__{
      _index: response["_index"],
      _type: response["_type"],
      _id: response["_id"],
      _score: response["_score"],
      _source: response["_source"],
      fields: response["fields"]
    }
  end

  @type t :: %__MODULE__{
          _index: String.t(),
          _type: String.t(),
          _id: String.t(),
          _score: float() | nil,
          _source: map() | nil,
          fields: map() | nil
        }
end
