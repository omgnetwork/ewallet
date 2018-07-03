defmodule AdminAPI.V1.AccountHelper do
  @moduledoc """
  Simple helper module to access accounts from controllers.
  """
  alias EWalletDB.{User, Key}

  def get_accessible_account_uuids(%{admin_user: admin_user}) do
    User.get_all_accessible_account_uuids(admin_user)
  end

  def get_accessible_account_uuids(%{key: key}) do
    Key.get_all_accessible_account_uuids(key)
  end
end
