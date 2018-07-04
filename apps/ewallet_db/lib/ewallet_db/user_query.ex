defmodule EWalletDB.UserQuery do
  @moduledoc """
  Helper functions to manipulate a `EWalletDB.User`'s query.
  """
  import Ecto.Query
  alias EWalletDB.{Membership, User}

  @doc """
  Scopes the given user query to users with one or more membership only.
  If a `queryable` is not given, it automatically creates a new User query.
  """
  def where_has_membership(queryable \\ User) do
    # Returns only the User struct, not the Memberships
    queryable
    |> join(:inner, [u], m in Membership, u.uuid == m.user_uuid)
    |> distinct(true)
    |> select([c], c)
  end

  def where_has_membership_in_accounts(account_uuids, queryable \\ User) do
    # Returns only the User struct, not the Memberships
    queryable
    |> join(:inner, [u], m in Membership, u.uuid == m.user_uuid and
                                          m.account_uuid in ^account_uuids)
    |> distinct(true)
    |> select([c], c)
  end
end
