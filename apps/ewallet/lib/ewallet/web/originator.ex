defmodule EWallet.Web.Originator do
  def extract(%{key: key}) do
    key
  end

  def extract(%{admin_user: admin_user}) do
    admin_user
  end
end
