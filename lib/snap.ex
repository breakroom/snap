defmodule Snap do
  @moduledoc """
  The Snap module handles basic interaction with Elasticsearch: making simple
  requests and parsing responses.
  """

  alias Snap.Request

  def get(cluster, path, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, "GET", path, nil, params, headers, opts)
  end

  def post(cluster, path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, "POST", path, body, params, headers, opts)
  end

  def put(cluster, path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, "PUT", path, body, params, headers, opts)
  end

  def delete(cluster, path, params \\ [], headers \\ [], opts \\ []) do
    Request.request(cluster, "DELETE", path, nil, params, headers, opts)
  end
end
