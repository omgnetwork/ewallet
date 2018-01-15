defmodule KuberaDB.UserQuery do
  @moduledoc """
  Helper functions to manipulate a `KuberaDB.User`'s query.
  """
  import Ecto.Query
  alias KuberaDB.{Membership, User}

  @doc """
  Scopes the given user query to users with one or more membership only.
  If a `queryable` is not given, it automatically creates a new User query.
  """
  def where_has_membership(queryable \\ User) do
    queryable
    |> join(:inner, [u], m in Membership, u.id == m.user_id)
    |> select([c], c) # Returns only the User struct, not the Memberships
  end
end
