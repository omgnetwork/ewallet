# credo:disable-for-this-file
defmodule EWalletAPI.V1.UserChannel do
  @moduledoc """
  Represents the user channel.
  """
  use Phoenix.Channel, async: false
  alias EWalletDB.User
  alias EWallet.UserPolicy

  def join(
        "user:" <> user_id,
        _params,
        %{
          assigns: %{auth: auth}
        } = socket
      ) do
    with %User{} = user <- User.get(user_id) || User.get_by_provider_user_id(user_id),
         :ok <- Bodyguard.permit(UserPolicy, :join, auth, user) do
      {:ok, socket}
    else
      _ -> {:error, :forbidden_channel}
    end
  end

  def join(_, _, _), do: {:error, :invalid_parameter}
end
