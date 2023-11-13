defmodule Snap.Document do
  @moduledoc """
  Convenience API into the [Document API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html).
  """

  alias Snap.Cluster.Namespace

  @doc """
  Gets a document in the index with the specified ID
  """
  def get(cluster, index, id, params \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.get(cluster, "/#{namespaced_index}/_doc/#{id}", params, [], opts)
  end

  @doc """
  Creates a document in the index with the specified ID. Fails if a document already exists at that ID.
  """
  def create(cluster, index, document, id, params \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.post(cluster, "/#{namespaced_index}/_create/#{id}", document, params, [], opts)
  end

  @doc """
  Creates or updates a document in the index with the specified ID. Overwrite it if it already exists.
  """
  def index(cluster, index, document, id, params \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.put(cluster, "/#{namespaced_index}/_doc/#{id}", document, params, [], opts)
  end

  @doc """
  Creates a new document in the index. The ID will be assigned automatically.
  """
  def add(cluster, index, document, params \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.post(cluster, "/#{namespaced_index}/_doc", document, params, [], opts)
  end

  @doc """
  Updates the document at the ID. See the ElasticSearch/OpenSearch docs for more
  details about [how updates are
  performed](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-update.html).
  """
  def update(cluster, index, body, id, params \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.post(cluster, "/#{namespaced_index}/_update/#{id}", body, params, [], opts)
  end

  @doc """
  Deletes a document in the index at the specified ID.
  """
  def delete(cluster, index, id, params \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.delete(cluster, "/#{namespaced_index}/_doc/#{id}", params, [], opts)
  end
end
