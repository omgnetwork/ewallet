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

defmodule LocalLedgerDB.EntryTest do
  use ExUnit.Case, async: true
  import LocalLedgerDB.Factory
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID
  alias LocalLedgerDB.{Entry, Errors.InsufficientFundsError, Repo}

  @uuid_regex ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  defp build_valid_entry do
    build_entry(%{})
  end

  defp build_entry(attrs) do
    Entry.changeset(%Entry{}, params_for(:entry, attrs))
  end

  defp insert_valid_entry do
    insert_entry(%{})
  end

  defp insert_entry(attrs, name \\ :entry) do
    params = params_for(name, attrs)

    {_, entry} =
      %Entry{}
      |> Entry.changeset(params)
      |> Repo.insert()

    entry
  end

  defp insert_entries_with_amounts(credit, debit) do
    {:ok, transaction} = :transaction |> build |> Repo.insert()
    {:ok, token} = :token |> build |> Repo.insert()
    {:ok, balance} = :wallet |> build |> Repo.insert()

    attrs = %{
      amount: credit,
      type: Entry.credit_type(),
      transaction_uuid: transaction.uuid,
      wallet_address: balance.address,
      token_id: token.id
    }

    insert_entry(attrs, :empty_entry)

    insert_entry(
      %{attrs | amount: debit, type: Entry.debit_type()},
      :empty_entry
    )

    {token, balance}
  end

  defp transfer(balance, token, amount, type) do
    {:ok, transaction} = :transaction |> build |> Repo.insert()

    attrs = %{
      amount: amount,
      type: Entry.credit_type(),
      transaction_uuid: transaction.uuid,
      wallet_address: balance.address,
      token_id: token.id
    }

    insert_entry(%{attrs | amount: amount, type: type}, :empty_entry)
  end

  describe "initialization" do
    test "generates a UUID" do
      entry = insert_valid_entry()

      assert String.match?(entry.uuid, @uuid_regex)
    end

    test "generates the inserted_at and updated_at values" do
      entry = insert_valid_entry()

      assert entry.inserted_at != nil
      assert entry.updated_at != nil
    end
  end

  describe "validations" do
    test "has a valid factory" do
      entry = build_valid_entry()

      assert entry.valid?
    end

    test "prevents creation of an entry without an amount" do
      entry = build_entry(%{amount: nil})

      refute entry.valid?
      assert entry.errors == [amount: {"can't be blank", [validation: :required]}]
    end

    test "prevents creation of an entry without a type" do
      entry = build_entry(%{type: nil})

      refute entry.valid?
      assert entry.errors == [type: {"can't be blank", [validation: :required]}]
    end

    test "prevents creation of an entry without a token id" do
      entry = build_entry(%{token_id: nil})

      refute entry.valid?
      assert entry.errors == [token_id: {"can't be blank", [validation: :required]}]
    end

    test "prevents creation of an entry without an invalid token" do
      entry = insert_entry(%{token_id: "AAA"})

      refute entry.valid?
      assert entry.errors == [token_id: {"does not exist", [constraint: :foreign, constraint_name: "entry_token_id_fkey"]}]
    end

    test "prevents creation of an entry without a balance" do
      entry = build_entry(%{wallet_address: nil})

      refute entry.valid?
      assert entry.errors == [wallet_address: {"can't be blank", [validation: :required]}]
    end

    test "prevents creation of an entry without a non existing balance" do
      entry = insert_entry(%{wallet_address: "123"})

      refute entry.valid?
      assert entry.errors == [wallet_address: {"does not exist", [constraint: :foreign, constraint_name: "entry_wallet_address_fkey"]]}]
    end

    test "prevents creation of an entry without a transction" do
      assert_raise Postgrex.Error, ~r/violates not-null constraint/, fn ->
        insert_entry(%{transaction_uuid: nil})
      end
    end

    test "prevents creation of an entry without a non existing transaction" do
      entry = insert_entry(%{transaction_uuid: UUID.generate()})

      refute entry.valid?
      assert entry.errors == [transaction_uuid: {"does not exist", [constraint: :foreign, constraint_name: "entry_transaction_uuid_fkey"]}]
    end
  end

  describe "check_balance/1" do
    test "returns :ok if the balance has enough funds" do
      {token, balance} = insert_entries_with_amounts(200, 100)

      res =
        Entry.check_balance(%{
          amount: 80,
          token_id: token.id,
          address: balance.address
        })

      assert res == :ok
    end

    test "raises InsufficientFundsError if the balance does not
          have enough funds" do
      {token, balance} = insert_entries_with_amounts(200, 130)

      assert_raise InsufficientFundsError, fn ->
        Entry.check_balance(%{
          amount: 80,
          token_id: token.id,
          address: balance.address
        })
      end
    end
  end

  describe "calculate_all_balances/2" do
    test "returns the correct wallets for each token" do
      {:ok, balance} = :wallet |> build |> Repo.insert()

      {:ok, omg} = :token |> build(id: "tok_OMG_123") |> Repo.insert()
      {:ok, knc} = :token |> build(id: "tok_KNC_456") |> Repo.insert()
      {:ok, btc} = :token |> build(id: "tok_BTC_789") |> Repo.insert()

      transfer(balance, omg, 100, Entry.debit_type())
      transfer(balance, omg, 300, Entry.credit_type())
      transfer(balance, omg, 500, Entry.credit_type())
      transfer(balance, knc, 100, Entry.credit_type())
      transfer(balance, btc, 100, Entry.credit_type())
      transfer(balance, btc, 200, Entry.credit_type())

      wallets = Entry.calculate_all_balances(balance.address)
      assert wallets == %{"tok_BTC_789" => 300, "tok_KNC_456" => 100, "tok_OMG_123" => 700}
    end

    test "works even if the wallet only had debits" do
      {:ok, balance} = :wallet |> build |> Repo.insert()
      {:ok, omg} = :token |> build(id: "tok_OMG_123") |> Repo.insert()

      transfer(balance, omg, 100, Entry.debit_type())
      transfer(balance, omg, 300, Entry.debit_type())
      transfer(balance, omg, 500, Entry.debit_type())

      wallets = Entry.calculate_all_balances(balance.address)
      assert wallets == %{"tok_OMG_123" => -900}
    end

    test "returns the correct balance for the specified token" do
      {:ok, balance} = :wallet |> build |> Repo.insert()
      {:ok, omg} = :token |> build(id: "tok_OMG_123") |> Repo.insert()
      {:ok, knc} = :token |> build(id: "tok_KNC_456") |> Repo.insert()

      transfer(balance, omg, 100, Entry.debit_type())
      transfer(balance, omg, 300, Entry.credit_type())
      transfer(balance, omg, 500, Entry.credit_type())
      transfer(balance, knc, 100, Entry.credit_type())

      wallets =
        Entry.calculate_all_balances(balance.address, %{
          token_id: "tok_OMG_123"
        })

      assert wallets == %{"tok_OMG_123" => 300 + 500 - 100}
    end

    test "calculates all wallets since specified date" do
      {:ok, balance} = :wallet |> build |> Repo.insert()
      {:ok, omg} = :token |> build(id: "tok_OMG_123") |> Repo.insert()
      {:ok, knc} = :token |> build(id: "tok_KNC_456") |> Repo.insert()

      transfer(balance, omg, 100, Entry.debit_type())
      transfer(balance, omg, 300, Entry.credit_type())
      transfer(balance, omg, 500, Entry.credit_type())
      transfer(balance, knc, 100, Entry.credit_type())

      entries = Repo.all(Entry)
      entry = Enum.at(entries, 1)

      all_wallets = Entry.calculate_all_balances(balance.address)

      wallets =
        Entry.calculate_all_balances(balance.address, %{
          since: entry.inserted_at
        })

      assert all_wallets == %{"tok_KNC_456" => 100, "tok_OMG_123" => 300 + 500 - 100}
      assert wallets == %{"tok_KNC_456" => 100, "tok_OMG_123" => 500}
    end

    test "calculates all wallets up to the specified date" do
      {:ok, balance} = :wallet |> build |> Repo.insert()
      {:ok, omg} = :token |> build(id: "tok_OMG_123") |> Repo.insert()
      {:ok, knc} = :token |> build(id: "tok_KNC_456") |> Repo.insert()

      transfer(balance, omg, 100, Entry.debit_type())
      transfer(balance, omg, 300, Entry.credit_type())
      transfer(balance, omg, 500, Entry.credit_type())
      transfer(balance, knc, 100, Entry.credit_type())

      entries = Repo.all(Entry)
      entry = Enum.at(entries, 1)

      all_wallets = Entry.calculate_all_balances(balance.address)

      wallets =
        Entry.calculate_all_balances(balance.address, %{
          upto: entry.inserted_at
        })

      assert all_wallets == %{"tok_KNC_456" => 100, "tok_OMG_123" => 300 + 500 - 100}
      assert wallets == %{"tok_OMG_123" => 300 - 100}
    end

    test "calculates all wallets between the specified 'since' date and 'upto' date" do
      {:ok, balance} = :wallet |> build |> Repo.insert()
      {:ok, omg} = :token |> build(id: "tok_OMG_123") |> Repo.insert()

      transfer(balance, omg, 300, Entry.credit_type())
      transfer(balance, omg, 500, Entry.credit_type())
      transfer(balance, omg, 100, Entry.credit_type())
      transfer(balance, omg, 1200, Entry.credit_type())
      transfer(balance, omg, 250, Entry.credit_type())

      entries = Repo.all(Entry)
      entry_1 = Enum.at(entries, 1)
      entry_2 = Enum.at(entries, 3)

      all_wallets = Entry.calculate_all_balances(balance.address)

      wallets =
        Entry.calculate_all_balances(balance.address, %{
          since: entry_1.inserted_at,
          upto: entry_2.inserted_at
        })

      assert all_wallets == %{"tok_OMG_123" => 300 + 500 + 100 + 1200 + 250}
      assert wallets == %{"tok_OMG_123" => 100 + 1200}
    end
  end

  describe "#calculate_current_amount" do
    test "returns the correct current balance amount" do
      {token, balance} = insert_entries_with_amounts(200, 130)

      amount = Entry.calculate_current_amount(balance.address, token.id)
      assert amount == 70
    end
  end
end
