defmodule AdminAPI.V1.UserSerializer do
  @moduledoc """
  Serializes user(s) into V1 JSON response format.
  """
  alias AdminAPI.V1.PaginatorSerializer
  alias EWallet.Web.{Date, Paginator}

  def to_json(%Paginator{} = paginator) do
    PaginatorSerializer.to_json(paginator, &to_json/1)
  end
  def to_json(user) when is_map(user) do
    %{
      object: "user",
      id: user.id,
      username: user.username,
      provider_user_id: user.provider_user_id,
      email: user.email,
      metadata: user.metadata,
      avatar: EWalletDB.Uploaders.Avatar.urls({user.avatar, user}),
      created_at: Date.to_iso8601(user.inserted_at),
      updated_at: Date.to_iso8601(user.updated_at)
    }
  end
end
