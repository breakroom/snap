defmodule Snap.MetricsAggregation do
  @moduledoc """
  Represents an individual aggregation dictionary from a
  [Search Aggregation API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html)
  response.
  """
  defstruct [:value, type: :metrics]

  def new(response) do
    %__MODULE__{
      value: response
    }
  end

  @type t :: %__MODULE__{
          value: map(),
          type: atom()
        }
end
