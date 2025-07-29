defmodule Snap.DeleteResponse do
  @moduledoc """
  Represents the response from ElasticSearch's [`delete_by_query` request](https://docs.opensearch.org/2.19/api-reference/document-apis/delete-by-query/).
  """
  defstruct [
    :took,
    :timed_out,
    :total,
    :deleted,
    :batches,
    :version_conflicts,
    :noops,
    :retries,
    :throttled_millis,
    :requests_per_second,
    :throttled_until_millis,
    :failures
  ]

  def new(response) do
    %__MODULE__{
      took: response["took"],
      timed_out: response["timed_out"],
      total: response["total"],
      deleted: response["deleted"],
      batches: response["batches"],
      version_conflicts: response["version_conflicts"],
      noops: response["noops"],
      retries: response["retries"],
      throttled_millis: response["throttled_millis"],
      requests_per_second: response["requests_per_second"],
      throttled_until_millis: response["throttled_until_millis"],
      failures: response["failures"]
    }
  end
end
