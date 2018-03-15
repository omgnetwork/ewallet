defmodule EWallet.Web.V1.TransactionRequestSerializer do
  @moduledoc """
  Serializes transaction request data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.MintedTokenSerializer
  alias EWallet.Web.Date
  alias EWalletDB.Repo
  alias EWalletDB.TransactionRequest

  def serialize(%TransactionRequest{} = transaction_request) do
    transaction_request = Repo.preload(transaction_request, :minted_token)

    %{
      object: "transaction_request",
      id: transaction_request.id,
      type: transaction_request.type,
      minted_token_id: transaction_request.minted_token.friendly_id,
      minted_token: MintedTokenSerializer.serialize(transaction_request.minted_token),
      amount: transaction_request.amount,
      address: transaction_request.balance_address,
      user_id: transaction_request.user_id,
      account_id: transaction_request.account_id,
      correlation_id: transaction_request.correlation_id,
      status: transaction_request.status,
      created_at: Date.to_iso8601(transaction_request.inserted_at),
      updated_at: Date.to_iso8601(transaction_request.updated_at)
    }
  end
  def serialize(%NotLoaded{}), do: nil
end
