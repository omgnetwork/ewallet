defmodule LocalLedgerDB.Factory do
  @moduledoc """
  Factories used for testing.
  """
  use ExMachina.Ecto, repo: LocalLedgerDB.Repo
  alias Ecto.UUID
  alias LocalLedgerDB.MintedToken
  alias LocalLedgerDB.Balance
  alias LocalLedgerDB.Entry
  alias LocalLedgerDB.Transaction

  def minted_token_factory do
    %MintedToken{
      friendly_id: "OMG:123",
      metadata: %{
        external_id: %{
          app: "Kubera",
          uuid: "123"
        }
      }
    }
  end

  def balance_factory do
    %Balance{
      address: "test",
      metadata: %{
        external_id: %{
          app: "Kubera",
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
      type: Transaction.credit_type
    }
  end

  def transaction_factory do
    %Transaction{
      amount: 100,
      type: Transaction.credit_type,
      minted_token_friendly_id: insert(:minted_token).friendly_id,
      balance_address: insert(:balance).address,
      entry_id: insert(:entry).id
    }
  end
end
