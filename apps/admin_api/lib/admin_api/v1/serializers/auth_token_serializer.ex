defmodule AdminAPI.V1.AuthTokenSerializer do
  @moduledoc """
  Serializes authentication token data into V1 response format.
  """
  alias EWallet.AccountPolicy
  alias EWallet.Web.V1.{UserSerializer, AccountSerializer}
  alias EWalletDB.Account
  alias EWalletDB.Helpers.{Assoc, Preloader}

  def serialize(auth_token) do
    auth_token = Preloader.preload(auth_token, [:user, :account])
    master_account = Account.get_master_account()
    master_admin = AccountPolicy.authorize(:godmode, auth_token.user.id, master_account.id)

    %{
      object: "authentication_token",
      authentication_token: auth_token.token,
      user_id: Assoc.get(auth_token, [:user, :id]),
      user: UserSerializer.serialize(auth_token.user),
      account_id: Assoc.get(auth_token, [:account, :id]),
      account: AccountSerializer.serialize(auth_token.account),
      master_admin: master_admin
    }
  end
end
