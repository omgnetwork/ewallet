defmodule EWallet.KeyPolicy do
  @moduledoc """
  The authorization policy for keys.
  """
  @behaviour Bodyguard.Policy
  alias EWalletDB.{Account, User}

  def authorize(:all, _user_or_key, _key_id), do: true

  def authorize(:create, %{key: key}, _key_id) do
    Account.get_master_account().uuid == key.account.uuid
  end

  def authorize(:create, %{admin_user: user}, _key_id) do
    User.master_admin?(user.id)
  end

  def authorize(:delete, %{key: key}, key_id) do
    Account.get_master_account().uuid == key.account.uuid && key.id != key_id
  end

  def authorize(:delete, %{admin_user: user}, _key_id) do
    User.master_admin?(user.id)
  end

  def authorize(_, _, _), do: false
end
