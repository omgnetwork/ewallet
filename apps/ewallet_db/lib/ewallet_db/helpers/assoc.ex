defmodule EWalletDB.Helpers.Assoc do
  @moduledoc """
  The module that provides helpers for working with associations.
  """

  @doc """
  Retrieves a value in a nested association. Returns `nil` if it finds `nil` while recursing.

  This function in suitable when an [`Access`](https://hexdocs.pm/elixir/Access.html)-like
  behavior is needed but the behavior is not implemented, e.g. due to potential naming conflicts
  with the schema's `fetch/2`, `get/3`, etc.

  This function does not preload the associations.
  """
  @spec get(Ecto.Schema.t(), list(atom() | String.t())) :: Ecto.Schema.t()
  def get(struct, nested) when length(nested) > 1 do
    [field | remaining] = nested

    # Stops recursing and returns nil if the retrieved association is nil
    case Map.get(struct, field) do
      nil -> nil
      assoc -> get(assoc, remaining)
    end
  end
  def get(struct, nested) when length(nested) == 1 do
    field = List.first(nested)
    Map.get(struct, field)
  end
end
