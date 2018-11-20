defmodule EWallet.Web.V1.UserSerializer do
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

  def serialize(users) when is_list(users) do
    %{
      object: "list",
      data: Enum.map(users, &serialize/1)
    }
  end

  def serialize(%User{} = user) do
    %{
      object: "user",
      id: user.id,
      socket_topic: "user:#{user.id}",
      username: user.username,
      full_name: user.full_name,
      calling_name: user.calling_name,
      provider_user_id: user.provider_user_id,
      email: user.email,
      metadata: user.metadata || %{},
      encrypted_metadata: user.encrypted_metadata || %{},
      avatar: Avatar.urls({user.avatar, user}),
      created_at: Date.to_iso8601(user.inserted_at),
      updated_at: Date.to_iso8601(user.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize(%NotLoaded{}, _), do: nil

  def serialize(users, :id) when is_list(users) do
    Enum.map(users, fn user -> user.id end)
  end

  def serialize(nil, _), do: nil
end
