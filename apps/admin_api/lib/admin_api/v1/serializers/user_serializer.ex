defmodule AdminAPI.V1.UserSerializer do
  @moduledoc """
  Serializes user(s) into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator, V1.PaginatorSerializer}
  alias EWalletDB.Uploaders.Avatar
  alias EWalletDB.User

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end
  def serialize(%User{} = user) do
    %{
      object: "user",
      id: user.id,
      username: user.username,
      provider_user_id: user.provider_user_id,
      email: user.email,
      metadata: user.metadata,
      encrypted_metadata: user.encrypted_metadata,
      avatar: Avatar.urls({user.avatar, user}),
      created_at: Date.to_iso8601(user.inserted_at),
      updated_at: Date.to_iso8601(user.updated_at)
    }
  end
  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
