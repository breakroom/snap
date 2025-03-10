defmodule Snap.Aggregation do
  @moduledoc """
  Represents an individual aggregation dictionary from a
  [Search Aggregation API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html)
  response.
  """
  defstruct ~w[
    buckets
    doc_count
    doc_count_error_upper_bound
    interval
    sum_other_doc_count
    value
  ]a ++
              [
                type: :buckets
              ]

  def new(response) do
    %__MODULE__{
      buckets: response["buckets"],
      doc_count: response["doc_count"],
      doc_count_error_upper_bound: response["doc_count_error_upper_bound"],
      interval: response["interval"],
      sum_other_doc_count: response["sum_other_doc_count"],
      value: response["value"]
    }
  end

  @type t :: %__MODULE__{
          buckets: list(map()),
          doc_count: integer(),
          doc_count_error_upper_bound: integer(),
          interval: integer(),
          sum_other_doc_count: integer(),
          value: integer(),
          type: atom()
        }
end
