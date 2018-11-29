# credo:disable-for-this-file
defmodule AdminAPI.V1.AccountChannel do
  @moduledoc """
  Represents the account channel.
  """
  use Phoenix.Channel, async: false
  alias EWallet.AccountPolicy

  def join("account:" <> account_id, _params, %{assigns: %{auth: auth}} = socket) do
    case permit(:join, auth, account_id) do
      :ok -> {:ok, socket}
      _ -> {:error, :forbidden_channel}
    end
  end

  def join(_, _, _), do: {:error, :invalid_parameter}

  @spec permit(:join, map(), String.t() | nil) :: :ok | {:error, any()} | no_return()
  defp permit(action, params, account_id) do
    Bodyguard.permit(AccountPolicy, action, params, account_id)
  end
end
