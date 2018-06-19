# credo:disable-for-this-file
defmodule EWalletAPI.V1.TransactionRequestChannel do
  @moduledoc """
  Represents the transaction request channel.
  """
  use Phoenix.Channel
  alias EWalletDB.{User, TransactionRequest}

  def join("transaction_request:" <> request_id, _params, %{assigns: %{auth: auth}} = socket) do
    request_id
    |> TransactionRequest.get()
    |> join_as(auth, socket)
  end

  def join(_, _, _), do: {:error, :invalid_parameter}

  defp join_as(nil, _auth, _socket), do: {:error, :channel_not_found}

  defp join_as(request, %{authenticated: true, user: user}, socket) do
    user
    |> User.addresses()
    |> Enum.member?(request.wallet_address)
    |> case do
      true -> {:ok, socket}
      false -> {:error, :forbidden_channel}
    end
  end
end
