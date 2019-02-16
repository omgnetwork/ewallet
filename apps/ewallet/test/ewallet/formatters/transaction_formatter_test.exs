# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWallet.TransactionFormatterTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.TransactionFormatter
  alias EWalletDB.Account

  defp has_entry?(formatted, type, address, amount, token) do
    entries = formatted["entries"]

    assert Enum.any?(entries, fn entry ->
             entry["type"] == Atom.to_string(type) && entry["address"] == address &&
               entry["amount"] == amount && entry["token"]["id"] == token.id
           end)
  end

  describe "format/1" do
    test "returns the expected format" do
      transaction = insert(:transaction)

      assert TransactionFormatter.format(transaction) ==
               %{
                 "idempotency_token" => transaction.idempotency_token,
                 "metadata" => transaction.metadata,
                 "entries" => [
                   %{
                     "type" => "debit",
                     "address" => transaction.from_wallet.address,
                     "amount" => transaction.from_amount,
                     "token" => %{
                       "id" => transaction.from_token.id,
                       "metadata" => transaction.from_token.metadata
                     },
                     "metadata" => transaction.from_wallet.metadata
                   },
                   %{
                     "type" => "credit",
                     "address" => transaction.to_wallet.address,
                     "amount" => transaction.to_amount,
                     "token" => %{
                       "id" => transaction.to_token.id,
                       "metadata" => transaction.to_token.metadata
                     },
                     "metadata" => transaction.to_wallet.metadata
                   }
                 ]
               }
    end
  end

  describe "format/1 when `from_token` and `to_token` are the same" do
    test "returns the expected debit and credit entries" do
      from_wallet = insert(:wallet)
      to_wallet = insert(:wallet)
      omg = insert(:token)

      transaction =
        insert(
          :transaction,
          # From
          from_wallet: from_wallet,
          from_amount: 100,
          from_token: omg,
          # To
          to_wallet: to_wallet,
          to_amount: 100,
          to_token: omg
        )

      formatted = TransactionFormatter.format(transaction)

      assert has_entry?(formatted, :debit, from_wallet.address, 100, omg)
      assert has_entry?(formatted, :credit, to_wallet.address, 100, omg)
      assert Enum.count(formatted["entries"]) == 2
    end
  end

  describe "format/1 when `from_token` and `to_token` are different" do
    test "returns the expected debit and credit entries" do
      from_wallet = insert(:wallet)
      to_wallet = insert(:wallet)
      omg = insert(:token)
      eth = insert(:token)
      {:ok, exchange_account} = :account |> params_for() |> Account.insert()
      exchange_wallet = Account.get_primary_wallet(exchange_account)

      transaction =
        insert(:transaction, %{
          from_wallet: from_wallet,
          from_amount: 100,
          from_token: omg,
          to_wallet: to_wallet,
          to_amount: 100,
          to_token: eth,
          exchange_wallet: exchange_wallet
        })

      formatted = TransactionFormatter.format(transaction)

      assert has_entry?(formatted, :debit, from_wallet.address, 100, omg)
      assert has_entry?(formatted, :credit, exchange_wallet.address, 100, omg)
      assert has_entry?(formatted, :debit, exchange_wallet.address, 100, eth)
      assert has_entry?(formatted, :credit, to_wallet.address, 100, eth)
      assert Enum.count(formatted["entries"]) == 4
    end
  end

  describe "format/1 for cross-token transfers when `from` is also the exchange wallet" do
    test "returns the expected debit and credit entries" do
      {:ok, exchange_account} = :account |> params_for() |> Account.insert()
      exchange_wallet = Account.get_primary_wallet(exchange_account)
      to_wallet = insert(:wallet)
      omg = insert(:token)
      eth = insert(:token)

      transaction =
        insert(:transaction, %{
          from_wallet: exchange_wallet,
          from_amount: 100,
          from_token: omg,
          to_wallet: to_wallet,
          to_amount: 100,
          to_token: eth,
          exchange_wallet: exchange_wallet
        })

      formatted = TransactionFormatter.format(transaction)

      assert has_entry?(formatted, :debit, exchange_wallet.address, 100, eth)
      assert has_entry?(formatted, :credit, to_wallet.address, 100, eth)
      assert Enum.count(formatted["entries"]) == 2
    end
  end

  describe "format/1 for cross-token transfers when `to` is also the exchange wallet" do
    test "returns the expected debit and credit entries" do
      {:ok, exchange_account} = :account |> params_for() |> Account.insert()
      exchange_wallet = Account.get_primary_wallet(exchange_account)
      from_wallet = insert(:wallet)
      omg = insert(:token)
      eth = insert(:token)

      transaction =
        insert(:transaction, %{
          from_wallet: from_wallet,
          from_amount: 100,
          from_token: omg,
          to_wallet: exchange_wallet,
          to_amount: 100,
          to_token: eth,
          exchange_wallet: exchange_wallet
        })

      formatted = TransactionFormatter.format(transaction)

      assert has_entry?(formatted, :debit, from_wallet.address, 100, omg)
      assert has_entry?(formatted, :credit, exchange_wallet.address, 100, omg)
      assert Enum.count(formatted["entries"]) == 2
    end
  end
end
