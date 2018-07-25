defmodule EWallet.Web.Preloader do
  @moduledoc """
  This module allows the preloading of specific associations for the given schema.
  It takes in a list of associations to preload as a list of atoms.
  """
  alias EWalletDB.Repo

  @doc """
  Preload the given list of associations.
  """
  @spec to_query(Ecto.Queryable.t(), [atom()]) :: {Ecto.Query.t()}
  def to_query(queryable, preload_fields) when is_list(preload_fields) do
    import Ecto.Query
    from(q in queryable, preload: ^preload_fields)
  end

  def to_query(queryable, _), do: queryable

  @doc """
  Preloads associations into the given record.
  """
  @spec preload_one(map, atom() | [atom()]) :: {:ok, Ecto.Schema.t()} | {:error, nil}
  def preload_one(record, preloads) when is_map(record) do
    case Repo.preload(record, List.wrap(preloads)) do
      nil -> {:error, nil}
      %{} = result -> {:ok, result}
    end
  end

  @doc """
  Preloads associations into the given records.
  """
  @spec preload_all(list(Ecto.Schema.t()), atom() | [atom()]) ::
          {:ok, [Ecto.Schema.t()]} | {:error, nil}
  def preload_all(record, preloads) do
    case Repo.preload(record, List.wrap(preloads)) do
      nil -> {:error, nil}
      result when is_list(result) -> {:ok, result}
    end
  end
end
