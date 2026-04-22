defmodule Snap.Document do
  @moduledoc """
  Convenience API into the [Document API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html).
  """

  alias Snap.Cluster.Namespace
  alias Snap.Request

  @doc """
  Gets a document in the index with the specified ID
  """
  def get(cluster, index, id, params \\ [], opts \\ []) do
    index = index |> Namespace.add_namespace_to_index(cluster) |> Request.encode_segment()
    id = Request.encode_segment(id)
    Snap.get(cluster, "/#{index}/_doc/#{id}", params, [], opts)
  end

  @doc """
  Creates a document in the index with the specified ID. Fails if a document already exists at that ID.
  """
  def create(cluster, index, document, id, params \\ [], opts \\ []) do
    index = index |> Namespace.add_namespace_to_index(cluster) |> Request.encode_segment()
    id = Request.encode_segment(id)
    Snap.post(cluster, "/#{index}/_create/#{id}", document, params, [], opts)
  end

  @doc """
  Creates or updates a document in the index with the specified ID. Overwrite it if it already exists.
  """
  def index(cluster, index, document, id, params \\ [], opts \\ []) do
    index = index |> Namespace.add_namespace_to_index(cluster) |> Request.encode_segment()
    id = Request.encode_segment(id)
    Snap.put(cluster, "/#{index}/_doc/#{id}", document, params, [], opts)
  end

  @doc """
  Creates a new document in the index. The ID will be assigned automatically.
  """
  def add(cluster, index, document, params \\ [], opts \\ []) do
    index = index |> Namespace.add_namespace_to_index(cluster) |> Request.encode_segment()
    Snap.post(cluster, "/#{index}/_doc", document, params, [], opts)
  end

  @doc """
  Updates the document at the ID. See the ElasticSearch/OpenSearch docs for more
  details about [how updates are
  performed](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-update.html).
  """
  def update(cluster, index, body, id, params \\ [], opts \\ []) do
    index = index |> Namespace.add_namespace_to_index(cluster) |> Request.encode_segment()
    id = Request.encode_segment(id)
    Snap.post(cluster, "/#{index}/_update/#{id}", body, params, [], opts)
  end

  @doc """
  Deletes a document in the index at the specified ID.
  """
  def delete(cluster, index, id, params \\ [], opts \\ []) do
    index = index |> Namespace.add_namespace_to_index(cluster) |> Request.encode_segment()
    id = Request.encode_segment(id)
    Snap.delete(cluster, "/#{index}/_doc/#{id}", params, [], opts)
  end
end
