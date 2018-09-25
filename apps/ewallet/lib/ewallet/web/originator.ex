defmodule EWallet.Web.Originator do
  @moduledoc """
  Module to extract the originator from the conn.assigns.
  """
  import EWalletDB.{AdminUser, Key}

  @spec extract(Map.t()) :: [%Key{}]
  def extract(%{key: key}) do
    key
  end

  @spec extract(Map.t()) :: [%AdminUser{}]
  def extract(%{admin_user: admin_user}) do
    admin_user
  end
end
