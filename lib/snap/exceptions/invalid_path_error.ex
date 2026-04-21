defmodule Snap.InvalidPathError do
  @moduledoc """
  Represents an error when a request path is malformed or contains
  directory-traversal segments.
  """

  @enforce_keys [:path]
  defexception [:path, :message]

  @type t :: %__MODULE__{
          path: term(),
          message: String.t()
        }

  @impl true
  def exception(opts) when is_list(opts) do
    path = Keyword.fetch!(opts, :path)

    message =
      "request path #{inspect(path)} is invalid: it contains traversal " <>
        "segments (`..` or `.`) or is not an absolute path"

    %__MODULE__{path: path, message: message}
  end
end
