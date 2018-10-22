defmodule AdminAPI.V1.AuthTokenSerializer do
  @moduledoc """
  Serializes authentication token data into V1 response format.
  """
  alias EWallet.Web.V1.{AccountSerializer, UserSerializer}
  alias EWalletDB.Helpers.Assoc
  alias EWalletDB.User

  def serialize(auth_token) do
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
