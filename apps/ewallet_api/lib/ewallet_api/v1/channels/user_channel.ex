# credo:disable-for-this-file
defmodule EWalletAPI.V1.UserChannel do
  @moduledoc """
  Represents the user channel.
  """
  use Phoenix.Channel, async: false
  alias EWalletDB.User

  def join(
        "user:" <> user_id,
        _params,
        %{
          assigns: %{auth: auth}
        } = socket
      ) do
    user = User.get(user_id) || User.get_by_provider_user_id(user_id)
    join_as(user, auth, socket)
  end

  def join(_, _, _), do: {:error, :invalid_parameter}

  defp join_as(nil, _auth, _socket), do: {:error, :channel_not_found}

  defp join_as(user, %{authenticated: true, user: auth_user}, socket) do
    same_user? = auth_user.id == user.id || auth_user.provider_user_id == user.provider_user_id

    case same_user? do
      true -> {:ok, socket}
      false -> {:error, :forbidden_channel}
    end
  end
end
