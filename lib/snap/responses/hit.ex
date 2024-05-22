defmodule Snap.Hit do
  @moduledoc """
  Represents an individual hit dictionary from a [Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html) response.
  """
  defstruct ~w[
    index
    type
    id
    score
    source
    fields
    explanation
    matched_queries
    highlight
    inner_hits
    sort
  ]a

  def new(response) do
    %__MODULE__{
      index: response["_index"],
      type: response["_type"],
      id: response["_id"],
      score: response["_score"],
      source: response["_source"],
      fields: response["fields"],
      explanation: response["_explanation"],
      matched_queries: response["matched_queries"],
      highlight: response["highlight"],
      inner_hits: build_inner_hits(response["inner_hits"]),
      sort: response["sort"]
    }
  end

  @type t :: %__MODULE__{
          index: String.t(),
          type: String.t() | nil,
          id: String.t(),
          score: float() | nil,
          source: map() | nil,
          fields: map() | nil,
          explanation: map() | nil,
          matched_queries: list(String.t()) | nil,
          highlight: map() | nil,
          inner_hits: %{String.t() => Snap.Hits.t()} | nil,
          sort: list() | nil
        }

  defp build_inner_hits(nil), do: nil

  defp build_inner_hits(inner_hits) when is_map(inner_hits) do
    inner_hits
    |> Enum.map(fn {key, value} ->
      {key, Snap.Hits.new(value["hits"])}
    end)
    |> Enum.into(%{})
  end
end
