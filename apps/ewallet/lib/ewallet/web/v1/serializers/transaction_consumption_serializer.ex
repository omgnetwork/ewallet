defmodule EWallet.Web.V1.TransactionConsumptionSerializer do
  @moduledoc """
  Serializes transaction request consumption data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.Date
  alias EWallet.Web.V1.{
    AccountSerializer,
    MintedTokenSerializer,
    TransactionSerializer,
    TransactionRequestSerializer,
    UserSerializer
  }
  alias EWalletDB.{Repo, TransactionConsumption}

  def serialize(%TransactionConsumption{} = consumption) do
    consumption = Repo.preload(consumption, [:transfer, :user, :account, :transaction_request])
    %{
      object: "transaction_consumption",
      id: consumption.external_id,
      socket_topic: "transaction_consumption:#{consumption.external_id}",
      status: consumption.status,
      approved: consumption.approved,
      amount: consumption.amount,
      minted_token_id: consumption[:minted_token][:friendly_id],
      minted_token: MintedTokenSerializer.serialize(consumption.minted_token),
      correlation_id: consumption.correlation_id,
      idempotency_token: consumption.idempotency_token,
      transaction_id: consumption[:transfer][:external_id],
      transaction: TransactionSerializer.serialize(consumption.transfer),
      user_id: consumption[:user][:external_id],
      user: UserSerializer.serialize(consumption.user),
      account_id: consumption[:account][:external_id],
      account: AccountSerializer.serialize(consumption.account),
      transaction_request_id: consumption[:transaction_request][:external_id],
      transaction_request: TransactionRequestSerializer.serialize(consumption.transaction_request),
      address: consumption.balance_address,
      expiration_date: consumption.expiration_date,
      metadata: consumption.metadata,
      encrypted_metadata: consumption.encrypted_metadata,
      created_at: Date.to_iso8601(consumption.inserted_at),
      updated_at: Date.to_iso8601(consumption.updated_at),
      finalized_at: Date.to_iso8601(consumption.finalized_at),
      expired_at: Date.to_iso8601(consumption.expired_at)
    }
  end
  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
