defmodule EWalletDB.Helpers.Preloader do
  @moduledoc """
  A helper module that helps with preloading records.
  """
  alias EWalletDB.Repo

  @doc """
  Takes the provided `:preload` option (if any) and preloads those associations.
  """
  def preload_option(records, opts) do
    case opts[:preload] do
      nil -> records
      preload -> Repo.preload(records, preload)
    end
  end

  @doc """
  Preloads the given struct with the given associations.

  This function simply calls `Repo.preload/2` but is useful for
  abstracting away the `Repo` module from non-DB callers.
  """
  def preload(struct, assocs) do
    Repo.preload(struct, assocs)
  end

  def get_unpreloaded_assocs(record, associations) do
    Enum.reduce(associations, [], fn {assoc, _schema}, acc ->
      actual_assoc = Map.get(record, assoc)

      case is_loaded?(actual_assoc) do
        true -> acc
        false -> [actual_assoc.__field__ | acc]
      end
    end)
  end

  def is_loaded?(%Ecto.Association.NotLoaded{} = _), do: false
  def is_loaded?(_), do: true
end
