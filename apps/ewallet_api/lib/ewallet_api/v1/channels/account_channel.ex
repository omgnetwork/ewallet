defmodule EWalletAPI.V1.AccountChannel do
  @moduledoc """
  Represents the account channel.
  """
  use Phoenix.Channel
  alias EWalletDB.Account

  def join("account:" <> account_id, _params, %{assigns: %{auth: auth}} = socket) do
    join_as(account_id, auth, socket)
  end

  def join(_, _, _), do: {:error, :invalid_parameter}

  defp join_as(account_id, %{authenticated: :provider}, socket) do
    account_id |> Account.get() |> respond(socket)
  end

  defp join_as(_, _, _), do: {:error, :forbidden_channel}

  defp respond(nil, _socket), do: {:error, :channel_not_found}
  defp respond(_account, socket), do: {:ok, socket}
end
