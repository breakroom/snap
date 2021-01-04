defmodule Snap.Auth.Plain do
  @moduledoc """
  Implements HTTP Basic Auth, if necessary.

  If the cluster config defines a username and password, an `Authorization:
  Basic` header is added to the request.

  ```
  config :my_app, MyApp.Cluster,
    url: "http://localhost:9200",
    username: "foo",
    password: "bar
  ```

  Or you can define a username and password in the URL itself:

  ```
  config :my_app, MyApp.Cluster,
    url: "http://username:password@localhost:9200"
  ```

  If no username or password is defined, no `Authorization` header is added,
  making it suitable for local development.
  """
  @behaviour Snap.Auth

  def sign(config, method, path, headers, body) do
    with [username, password] <- get_credentials_from_config(config) do
      auth_headers = [{"Authorization", encode_header(username, password)}]

      new_headers = headers ++ auth_headers

      {:ok, {method, path, new_headers, body}}
    else
      _ -> {:ok, {method, path, headers, body}}
    end
  end

  defp encode_header(username, password) do
    body = [username, password] |> Enum.join(":")

    "Basic " <> Base.encode64(body)
  end

  defp get_credentials_from_config(config) do
    with {:ok, username} when is_binary(username) <- Keyword.fetch(config, :username),
         {:ok, password} when is_binary(password) <- Keyword.fetch(config, :password) do
      [username, password]
    else
      _ -> get_credentials_from_url(config)
    end
  end

  defp get_credentials_from_url(config) do
    with {:ok, url} <- Keyword.fetch(config, :url),
         %URI{} = uri <- URI.parse(url) do
      get_credentials_from_uri(uri)
    end
  end

  defp get_credentials_from_uri(%URI{userinfo: nil}), do: nil

  defp get_credentials_from_uri(%URI{userinfo: userinfo}) do
    userinfo
    |> String.split(":")
    |> case do
      [username] -> [username, ""]
      [username, password] -> [username, password]
      _elements -> nil
    end
  end
end
