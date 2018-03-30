defmodule EWalletAPI.V1.AccountChannel do
  @moduledoc """
  Represents the account channel.
  """
  use Phoenix.Channel

  def join("account:" <> _account_id, _params, %{assigns: %{auth: auth}} = socket) do
    join_as(auth, socket)
  end
  def join(_, _, _), do: {:error, %{code: :invalid_parameter}}

  defp join_as(%{authenticated: :provider}, socket) do
    {:ok, socket}
  end

  defp join_as(_, _) do
    {:error, %{code: :forbidden_channel}}
  end
end
