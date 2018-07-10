defmodule AdminAPI.V1.AuthTokenSerializer do
  @moduledoc """
  Serializes authentication token data into V1 response format.
  """
  alias EWallet.Web.V1.{UserSerializer, AccountSerializer}
  alias EWalletDB.User
  alias EWalletDB.Helpers.{Assoc, Preloader}

  def serialize(auth_token) do
    auth_token = Preloader.preload(auth_token, [:user, :account])

    %{
      object: "authentication_token",
      authentication_token: auth_token.token,
      user_id: Assoc.get(auth_token, [:user, :id]),
      user: UserSerializer.serialize(auth_token.user),
      account_id: Assoc.get(auth_token, [:account, :id]),
      account: AccountSerializer.serialize(auth_token.account),
      master_admin: User.master_admin?(auth_token.user),
      role: User.get_role(auth_token.user.id, auth_token.account.id)
    }
  end
end
