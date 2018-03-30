defmodule EWalletAPI.V1.UserChannel do
  @moduledoc """
  Represents the user channel.
  """
  use Phoenix.Channel

  def join("user:" <> user_id, _params, %{assigns: %{auth: auth}} = socket) do
    case auth do
      %{authenticated: :provider} -> {:ok, socket}
      %{authenticated: :client} ->
        case socket.auth.user.id == user_id do
          true -> {:ok, socket}
          false -> {:error, %{code: :forbidden_channel}}
        end
    end
  end
  def join(_, _, _), do: {:error, %{code: :invalid_parameter}}
end
