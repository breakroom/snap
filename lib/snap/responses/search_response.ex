defmodule Snap.SearchResponse do
  @moduledoc """
  Represents the response from ElasticSearch's [Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html).

  Implements `Enumerable`, so you can iterate directly over the struct.
  """
  defstruct [:took, :timed_out, :shards, :hits, :suggest, :aggregations, :scroll_id, :pit_id]

  def new(response) do
    %__MODULE__{
      took: response["took"],
      timed_out: response["timed_out"],
      shards: response["_shards"],
      hits: Snap.Hits.new(response["hits"]),
      suggest: Snap.Suggests.new(response["suggest"]),
      aggregations: build_aggregations(response["aggregations"]),
      scroll_id: response["_scroll_id"],
      pit_id: response["pit_id"]
    }
  end

  @type t :: %__MODULE__{
          took: integer(),
          timed_out: boolean(),
          shards: map(),
          hits: Snap.Hits.t(),
          suggest: Snap.Suggests.t() | nil,
          aggregations: %{String.t() => Snap.Aggregation.t()} | nil,
          scroll_id: String.t() | nil,
          pit_id: map() | nil
        }

  def build_aggregations(nil) do
    nil
  end

  def build_aggregations(aggregations) when is_map(aggregations) do
    Map.new(aggregations, fn
      {key, %{"buckets" => _} = value} ->
        {key, Snap.Aggregation.new(value)}

      {key, %{"count" => _, "min" => _, "max" => _, "avg" => _, "sum" => _} = value} ->
        {key, Snap.MetricsAggregation.new(value)}

      # TODO: handle other MetricsAggregations
      {key, value} ->
        {key, Snap.MetricsAggregation.new(value)}
    end)
  end

  defimpl Enumerable do
    def reduce(_, {:halt, acc}, _fun), do: {:halted, acc}

    def reduce(%Snap.SearchResponse{hits: %Snap.Hits{hits: hits}}, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(%Snap.SearchResponse{hits: %Snap.Hits{hits: hits}}, &1, fun)}
    end

    def reduce(%Snap.SearchResponse{hits: %Snap.Hits{hits: []}}, {:cont, acc}, _fun),
      do: {:done, acc}

    def reduce(%Snap.SearchResponse{hits: %Snap.Hits{hits: [head | tail]}}, {:cont, acc}, fun) do
      reduce(%Snap.SearchResponse{hits: %Snap.Hits{hits: tail}}, fun.(head, acc), fun)
    end

    def count(%Snap.SearchResponse{hits: %Snap.Hits{hits: hits}}) do
      {:ok, Enum.count(hits)}
    end

    def member?(response, elem) do
      {:ok, Enum.member?(response.hits.hits, elem)}
    end

    def slice(_response), do: {:error, __MODULE__}
  end
end
