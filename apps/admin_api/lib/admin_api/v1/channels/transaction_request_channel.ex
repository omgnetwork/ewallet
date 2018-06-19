# credo:disable-for-this-file
defmodule AdminAPI.V1.TransactionRequestChannel do
  @moduledoc """
  Represents the transaction request channel.
  """
  use Phoenix.Channel
  alias EWalletDB.TransactionRequest

  def join("transaction_request:" <> request_id, _params, %{assigns: %{auth: auth}} = socket) do
    request_id
    |> TransactionRequest.get()
    |> join_as(auth, socket)
  end

  def join(_, _, _), do: {:error, :invalid_parameter}

  defp join_as(nil, _auth, _socket), do: {:error, :channel_not_found}

  defp join_as(_request, %{authenticated: true}, socket) do
    {:ok, socket}
  end
end
