defmodule EWallet.TransactionConsumptionGate do
  @moduledoc """
  Business logic to manage transaction request consumptions. This module is responsible for
  creating new consumptions, generating transfers and transactions. It can also be used to
  retrieve a specific consumption.

  It is basically an interface to the EWalletDB.TransactionConsumption schema.
  """
  alias EWallet.{
    TransactionConsumptionConsumerGate,
    TransactionConsumptionConfirmerGate
  }
  alias EWalletDB.TransactionConsumption

  @spec consume(Map.t()) :: {:ok, TransactionConsumption.t()} | {:error, Atom.t()}
  def consume(attrs) do
    TransactionConsumptionConsumerGate.consume(attrs)
  end

  @spec consume(User.t() | Balance.t(), Map.t()) ::
          {:ok, TransactionConsumption.t()} | {:error, Atom.t()}
  def consume(user_or_balance, attrs) do
    TransactionConsumptionConsumerGate.consume(user_or_balance, attrs)
  end

  @spec confirm(UUID.t(), Boolean.t(), Map.t()) ::
          {:ok, TransactionConsumption.t()}
          | {:error, Atom.t()}
          | {:error, TransactionConsumption.t(), Atom.t(), String.t()}
  def confirm(id, approved, owner) do
    TransactionConsumptionConfirmerGate.confirm(id, approved, owner)
  end
end
