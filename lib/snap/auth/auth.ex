defmodule Snap.Auth do
  @moduledoc """
  Defines how HTTP request is transformed to add authentication.
  """

  @type method :: String.t()
  @type url :: String.t()
  @type headers :: Mint.Types.headers()
  @type body :: iodata()
  @type opts :: Keyword.t()
  @type config :: map()

  @type response :: {:ok, {method, url, headers, body}} | {:error, term()}

  @doc """
  Modifies an HTTP request to include authentication details
  """
  @callback sign(config, method, url, headers, body) :: response()
end
