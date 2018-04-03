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
      nil     -> records
      preload -> Repo.preload(records, preload)
    end
  end

  @doc """
  Preloads the records with the given preloads.

  This provides a simple facade to the Ecto's preloader so non-schema codes do not rely on
  on `EWalletDB.Repo` functions directly.
  """
  @spec preload([Ecto.Schema.t()] | Ecto.Schema.t() | nil, [atom()]) ::
    [Ecto.Schema.t()] | Ecto.Schema.t() | nil
  def preload(records, preloads) do
    Repo.preload(records, preloads)
  end
end
