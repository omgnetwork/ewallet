defmodule EWallet.ExportPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.PolicyHelper
  alias EWalletDB.Account

  def authorize(:get, %{admin_user: admin_user}, export) do
    export.user_uuid == admin_user.uuid
  end

  def authorize(:get, %{key: key}, export) do
    export.key_uuid == key.uuid
  end

  def authorize(_, _, _), do: false
end
