defmodule LocalLedgerDB.Factory do
  @moduledoc """
  Factories used for testing.
  """
  use ExMachina.Ecto, repo: LocalLedgerDB.Repo
  alias Ecto.UUID
  alias LocalLedgerDB.{Entry, Wallet, Token, Transaction}

  def token_factory do
    %Token{
      id: sequence("tok_OMG_"),
      metadata: %{
        external_id: %{
          app: "EWallet",
          uuid: sequence("uuid")
        }
      }
    }
  end

  def wallet_factory do
    %Wallet{
      address: sequence("address"),
      metadata: %{
        external_id: %{
          app: "EWallet",
          uuid: sequence("uuid")
        }
      }
    }
  end

  def transaction_factory do
    %Transaction{
      idempotency_token: UUID.generate(),
      metadata: %{
        merchant_id: "123"
      }
    }
  end

  def empty_entry_factory do
    %{
      amount: 150,
      type: Entry.credit_type()
    }
  end

  def credit_factory do
    %Entry{
      amount: 150,
      type: Entry.credit_type(),
      transaction_uuid: insert(:transaction).uuid
    }
  end

  def debit_factory do
    %Entry{
      amount: 150,
      type: Entry.debit_type(),
      transaction_uuid: insert(:transaction).uuid
    }
  end

  def entry_factory do
    %Entry{
      amount: 10_000,
      type: Entry.credit_type(),
      token_id: insert(:token).id,
      wallet_address: insert(:wallet).address,
      transaction_uuid: insert(:transaction).uuid
    }
  end
end
