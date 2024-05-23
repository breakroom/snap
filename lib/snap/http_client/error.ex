defmodule Snap.HTTPClient.Error do
  @moduledoc """
  Represents an Error returned by the HTTPClient.

  Usually this wraps an error coming from the adapter that implements the `Snap.HTTPClient` behaviour,
  such as `Mint.HTTPError`.

  ## Struct Fields

    * `:reason` - the error reason represented by an atom.
    * `:origin` - the origin of the error. Contains the original error coming from the adapter of the
    `Snap.HTTPClient` behaviour, such as `Mint.HTTPError` or `Mint.TransportError`.
  """

  @keys [
    :reason,
    :origin
  ]

  @enforce_keys @keys
  defexception @keys

  @type t :: %__MODULE__{
          reason: atom(),
          origin: any()
        }

  @doc false
  def new(reason, origin) when is_atom(reason) do
    %__MODULE__{reason: reason, origin: origin}
  end

  @doc false
  def unknown(origin) do
    new(:unknown, origin)
  end

  @doc false
  @impl true
  def message(%__MODULE__{origin: origin}) when is_exception(origin) do
    Exception.message(origin)
  end

  @doc false
  def message(%__MODULE__{reason: reason}) do
    to_string(reason)
  end
end
