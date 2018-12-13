defmodule EWallet.Web.V1.CSV.TransactionSerializer do
  @moduledoc """
  Serializes token(s) into V1 CSV response format.
  """
  alias Ecto.Association.NotLoaded

  alias EWallet.Web.V1.{
    AccountSerializer,
    ErrorHandler,
    ExchangePairSerializer,
    PaginatorSerializer,
    TokenSerializer,
    UserSerializer,
    WalletSerializer
  }

  alias EWallet.Web.{Date, Paginator}
  alias EWalletConfig.Helpers.Assoc
  alias EWalletDB.Transaction

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def columns do
    [
      :id,
      :idempotency_token,
      :from_user_id,
      :from_account_id,
      :from_address,
      :from_amount,
      :from_token_id,
      :to_user_id,
      :to_account_id,
      :to_address,
      :to_amount,
      :to_token_id,
      :exchange_rate,
      :exchange_rate_calculated_at,
      :exchange_pair_id,
      :exchange_account_id,
      :exchange_wallet_address,
      :metadata,
      :encrypted_metadata,
      :status,
      :error_code,
      :error_description,
      :created_at,
      :updated_at
    ]
  end

  def serialize(%Transaction{} = transaction) do
    # IO.inspect(transaction)
    error = build_error(transaction)

    %{
      id: transaction.id,
      idempotency_token: transaction.idempotency_token,
      from_user_id: Assoc.get(transaction, [:from_user, :id]),
      from_account_id: Assoc.get(transaction, [:from_account, :id]),
      from_address: transaction.from,
      from_amount: transaction.from_amount,
      from_token_id: Assoc.get(transaction, [:from_token, :id]),
      to_user_id: Assoc.get(transaction, [:to_user, :id]),
      to_account_id: Assoc.get(transaction, [:to_account, :id]),
      to_address: transaction.to,
      to_amount: transaction.to_amount,
      to_token_id: Assoc.get(transaction, [:to_token, :id]),
      exchange_rate: transaction.rate,
      exchange_rate_calculated_at: Date.to_iso8601(transaction.calculated_at),
      exchange_pair_id: Assoc.get(transaction, [:exchange_pair, :id]),
      exchange_account_id: Assoc.get(transaction, [:exchange_account, :id]),
      exchange_wallet_address: Assoc.get(transaction, [:exchange_wallet, :address]),
      metadata: transaction.metadata || %{},
      encrypted_metadata: transaction.encrypted_metadata || %{},
      status: transaction.status,
      error_code: error[:code],
      error_description: error[:description],
      created_at: Date.to_iso8601(transaction.inserted_at),
      updated_at: Date.to_iso8601(transaction.updated_at)
    }
    |> Enum.into(%{}, fn {key, value} ->
      {key, format(value)}
    end)
  end

  def format(value) when is_map(value), do: Poison.encode!(value)
  def format(value), do: value

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  defp build_error(%Transaction{error_code: nil}), do: nil

  defp build_error(%Transaction{error_code: code, error_description: desc, error_data: data})
       when not is_nil(data) or not is_nil(desc) do
    ErrorHandler.build_error(code, data || desc, ErrorHandler.errors())
  end

  defp build_error(%Transaction{error_code: code}) do
    ErrorHandler.build_error(code, ErrorHandler.errors())
  end
end
