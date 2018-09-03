defmodule AdminAPI.V1.AccountHelper do
  @moduledoc """
  Simple helper module to access accounts from controllers.
  """
  alias EWalletDB.{Account, AuthToken, Helpers.Assoc, Key, User}
  alias Plug.Conn

  @spec get_current_account(Plug.Conn.t()) :: %Account{}
  def get_current_account(%Conn{assigns: %{admin_user: admin_user}} = conn) do
    conn.private[:auth_auth_token]
    |> AuthToken.get_by_token(:admin_api)
    |> Assoc.get([:account_uuid])
    |> case do
      nil ->
        User.get_account(admin_user)

      account_uuid ->
        Account.get_by(uuid: account_uuid)
    end
  end

  def get_current_account(%Conn{assigns: %{key: key}}) do
    key.account
  end

  @spec get_accessible_account_uuids(%{admin_user: %User{}} | %{key: %Key{}}) :: [String.t()]
  def get_accessible_account_uuids(%{admin_user: admin_user}) do
    User.get_all_accessible_account_uuids(admin_user)
  end

  def get_accessible_account_uuids(%{key: key}) do
    Key.get_all_accessible_account_uuids(key)
  end
end
