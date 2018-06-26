defmodule EWallet.AccountFetcher do
  @moduledoc """
  Module responsible for loading accounts.
  """
  alias EWalletDB.User

  def get_highest_account(%{admin_user: admin_user}) do
    User.get_highest_account(admin_user)
  end

  def get_highest_account(%{key: key}) do
    key.account
  end
end
