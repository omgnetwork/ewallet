# credo:disable-for-this-file
defmodule EWalletAPI.V1.TransactionRequestChannel do
  @moduledoc """
  Represents the transaction request channel.
  """
  use Phoenix.Channel, async: false
  alias EWalletDB.TransactionRequest
  alias EWallet.TransactionRequestPolicy

  def join("transaction_request:" <> request_id, _params, %{assigns: %{auth: auth}} = socket) do
    with %TransactionRequest{} = request <- TransactionRequest.get(request_id),
         :ok <- Bodyguard.permit(TransactionRequestPolicy, :join, auth, request) do
      {:ok, socket}
    else
      _ -> {:error, :forbidden_channel}
    end
  end

  def join(_, _, _), do: {:error, :invalid_parameter}
end
