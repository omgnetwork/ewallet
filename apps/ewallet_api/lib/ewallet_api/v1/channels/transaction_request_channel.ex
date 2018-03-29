defmodule EWalletAPI.V1.TransactionRequestChannel do
  @moduledoc """
  Represents the transaction request channel.
  """
  use Phoenix.Channel
  alias EWalletDB.{User, TransactionRequest}

  def join("transaction_request:" <> request_id, _params, %{assigns: %{auth: auth}} = socket) do
    case auth do
      %{authenticated: :provider} -> {:ok, socket}
      %{authenticated: :client, user: user} ->
        case TransactionRequest.get(request_id) do
          nil -> {:error, %{code: :channel_not_found}}
          request ->
            user
            |> User.addresses()
            |> Enum.member?(request.balance_address)
            |> case do
              true -> {:ok, socket}
              false -> {:error, %{code: :forbidden_channel}}
            end
        end
    end
  end
end
