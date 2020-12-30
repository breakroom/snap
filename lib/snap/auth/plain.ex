defmodule Snap.Auth.Plain do
  @behaviour Snap.Auth

  def sign(config, method, path, headers, body) do
    with {:ok, username} when is_binary(username) <- Map.fetch(config, :username),
         {:ok, password} when is_binary(password) <- Map.fetch(config, :password) do
      auth_headers = [{"Authorization", encode_header(username, password)}]

      new_headers = headers ++ auth_headers

      {:ok, {method, path, new_headers, body}}
    else
      _ -> {:ok, {method, path, headers, body}}
    end
  end

  defp encode_header(username, password) do
    body = username <> ":" <> password

    "Basic " <> Base.encode64(body)
  end
end
