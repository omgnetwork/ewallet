defmodule EWalletDB.UserQuery do
  @moduledoc """
  Helper functions to manipulate a `EWalletDB.User`'s query.
  """
  import Ecto.Query
  alias EWalletDB.{Membership, User}

  @doc """
  Scopes the given user query to users with one or more membership only.
  If a `queryable` is not given, it automatically creates a new User query.

  Returns a list of Users.
  """
  def where_has_membership(queryable \\ User) do
    # Returns only the User struct, not the Memberships
    queryable
    |> join(:inner, [u], m in assoc(u, :memberships))
    |> distinct(true)
    |> select([c], c)
  end

  @doc """
  Scopes the given user query to end users.

  Returns a list of Users.
  """
  def where_end_user(queryable \\ User) do
    queryable
    |> where(is_admin: false)
  end

  @doc """
  Scopes the given user query to users that have membership(s) in the given account uuids.

  Returns a list of Users.
  """
  def where_has_membership_in_accounts(account_uuids, queryable \\ User) do
    queryable
    |> join(
      :inner,
      [u],
      m in Membership,
      u.uuid == m.user_uuid and m.account_uuid in ^account_uuids
    )
    |> distinct(true)
    |> select([c], c)
  end
end
