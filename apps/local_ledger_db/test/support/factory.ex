defmodule LocalLedgerDB.Factory do
  @moduledoc """
  Factories used for testing.
  """
  use ExMachina.Ecto, repo: LocalLedgerDB.Repo
  alias Ecto.UUID
  alias LocalLedgerDB.{Entry, Wallet, MintedToken, Transaction}

  def minted_token_factory do
    %MintedToken{
      id: "tok_OMG_123",
      metadata: %{
        external_id: %{
          app: "EWallet",
          uuid: "123"
        }
      }
    }
  end

  def wallet_factory do
    %Wallet{
      address: "address",
      metadata: %{
        external_id: %{
          app: "EWallet",
          uuid: "123"
        }
      }
    }
  end

  def entry_factory do
    %Entry{
      correlation_id: UUID.generate(),
      metadata: %{
        merchant_id: "123"
      }
    }
  end

  def empty_transaction_factory do
    %{
      amount: 150,
      type: Transaction.credit_type()
    }
  end

  def credit_factory do
    %Transaction{
      amount: 150,
      type: Transaction.credit_type(),
      entry_uuid: insert(:entry).uuid
    }
  end

  def debit_factory do
    %Transaction{
      amount: 150,
      type: Transaction.debit_type(),
      entry_uuid: insert(:entry).uuid
    }
  end

  def transaction_factory do
    %Transaction{
      amount: 10_000,
      type: Transaction.credit_type(),
      minted_token_id: insert(:minted_token).id,
      wallet_address: insert(:wallet).address,
      entry_uuid: insert(:entry).uuid
    }
  end
end
