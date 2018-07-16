defmodule EWalletDB.Helpers.Assoc do
  @moduledoc """
  The module that provides helpers for working with associations.

  It contains functions that are suitable when an
  [`Access`](https://hexdocs.pm/elixir/Access.html)-like behavior is needed
  but the behavior is not implemented, e.g. due to potential naming conflicts
  with the schema's `fetch/2`, `get/3`, etc.

  ## Examples

  The usage is very similar to the `Access` behaviour.

  Given:

      iex> data = %{
        level_one: %{
          level_two: "content"
        }
      }

  This code below

      iex> Assoc.get(data, [:level_one, :level_two])
      "content"

      iex> Assoc.get(data, [:missing, :level_two])
      nil

  is equivalent to

      iex> data[:level_one][:level_two]
      "content"

      iex> data[:missing][:level_two]
      nil

  """

  @doc """
  Retrieves a value in a nested map. Returns `nil` if it finds `nil` while recursing.

  This function does not preload the associations.
  """
  @spec get(Ecto.Schema.t(), list(atom() | String.t())) :: Ecto.Schema.t()
  def get(struct, nested) when length(nested) > 1 do
    [field | remaining] = nested

    # Stops recursing and returns nil if the retrieved value is nil
    case Map.get(struct, field) do
      nil -> nil
      assoc -> get(assoc, remaining)
    end
  end

  def get(struct, nested) when length(nested) == 1 do
    field = List.first(nested)
    Map.get(struct, field)
  end

  @spec get_if_exists(Ecto.Schema.t() | nil, list(atom() | String.t())) :: Ecto.Schema.t()
  def get_if_exists(nil, _nested), do: nil
  def get_if_exists(struct, nested) when length(nested) > 1 do
    [field | remaining] = nested

    # Stops recursing and returns nil if the retrieved value is nil
    case Map.get(struct, field) do
      nil -> nil
      assoc -> get_if_exists(assoc, remaining)
    end
  end

  def get_if_exists(struct, nested) when length(nested) == 1 do
    field = List.first(nested)
    Map.get(struct, field)
  end
end
