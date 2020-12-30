defmodule Snap.Auth do
  @type method :: String.t()
  @type path :: String.t()
  @type headers :: Mint.Types.headers()
  @type body :: iodata()
  @type opts :: Keyword.t()

  @type response :: {:ok, {method, path, headers, body}} | {:error, term()}

  @callback sign(map(), method, path, headers, body) :: response()
end
