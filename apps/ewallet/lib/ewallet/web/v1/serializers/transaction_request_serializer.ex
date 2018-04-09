defmodule EWallet.Web.V1.TransactionRequestSerializer do
  @moduledoc """
  Serializes transaction request data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.V1.{
    AccountSerializer,
    MintedTokenSerializer,
    TransactionRequestSerializer,
    UserSerializer
  }
  alias EWallet.Web.Date
  alias EWalletDB.Helpers.{Assoc, Preloader}
  alias EWalletDB.Repo
  alias EWalletDB.TransactionRequest

  def serialize(%TransactionRequest{} = transaction_request) do
    transaction_request = Preloader.preload(transaction_request, [:account,
                                                                  :consumptions,
                                                                  :minted_token,
                                                                  :user])

    %{
      object: "transaction_request",
      id: transaction_request.id,
      socket_topic: "transaction_request:#{transaction_request.id}",
      type: transaction_request.type,
      amount: transaction_request.amount,
      status: transaction_request.status,
      correlation_id: transaction_request.correlation_id,
      minted_token_id: Assoc.get(transaction_request, [:minted_token, :friendly_id]),
      minted_token: MintedTokenSerializer.serialize(transaction_request.minted_token),
      address: transaction_request.balance_address,
      user_id: Assoc.get(transaction_request, [:user, :id]),
      user: UserSerializer.serialize(transaction_request.user),
      account_id: Assoc.get(transaction_request, [:account, :id]),
      account: AccountSerializer.serialize(transaction_request.account),
      require_confirmation: transaction_request.require_confirmation,
      current_consumptions_count: length(transaction_request.consumptions),
      max_consumptions: transaction_request.max_consumptions,
      consumption_lifetime: transaction_request.consumption_lifetime,
      expiration_reason: transaction_request.expiration_reason,
      allow_amount_override: transaction_request.allow_amount_override,
      metadata: transaction_request.metadata,
      encrypted_metadata: transaction_request.encrypted_metadata,
      expiration_date: Date.to_iso8601(transaction_request.expiration_date),
      expired_at: Date.to_iso8601(transaction_request.expired_at),
      created_at: Date.to_iso8601(transaction_request.inserted_at),
      updated_at: Date.to_iso8601(transaction_request.updated_at)
    }
  end
  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
