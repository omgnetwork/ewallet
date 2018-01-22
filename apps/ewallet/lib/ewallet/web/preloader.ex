defmodule EWallet.Web.Preloader do
  @moduledoc """
  This module allows the preloading of specific associations for the given schema.
  It takes in a list of associations to preload as a list of atoms.
  """
  import Ecto.Query

  @doc """
  Preload the given list of associations.
  """
  @spec to_query(Ecto.Query.t, List.t) :: {Ecto.Query.t}
  def to_query(queryable, preload_fields) when is_list(preload_fields) do
    from p in queryable, preload: ^preload_fields
  end
  def to_query(queryable, _), do: queryable
end
