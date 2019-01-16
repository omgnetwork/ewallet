# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule LocalLedgerDB.Factory do
  @moduledoc """
  Factories used for testing.
  """
  use ExMachina.Ecto, repo: LocalLedgerDB.Repo
  alias Ecto.UUID
  alias LocalLedgerDB.{Entry, CachedBalance, Token, Transaction, Wallet}

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

  def cached_balance_factory do
    %CachedBalance{
      amounts: %{insert(:token).id => 1_000, insert(:token).id => 10_000},
      computed_at: NaiveDateTime.utc_now(),
      wallet_address: insert(:wallet).address
    }
  end
end
