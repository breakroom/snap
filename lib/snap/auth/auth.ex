defmodule Snap.Auth do
  @moduledoc """
  Defines how HTTP request is transformed to add authentication.
  """

  alias Snap.Cluster
  alias Snap.HTTPClient

  @type t :: module()

  @type response ::
          {:ok, {HTTPClient.method(), HTTPClient.url(), HTTPClient.headers(), HTTPClient.body()}}
          | {:error, term()}

  @doc """
  Modifies an HTTP request to include authentication details
  """
  @callback sign(
              Cluster.config_opts(),
              HTTPClient.method(),
              HTTPClient.url(),
              HTTPClient.headers(),
              HTTPClient.body()
            ) :: response()
end
