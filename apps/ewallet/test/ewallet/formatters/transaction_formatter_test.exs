defmodule EWallet.TransactionFormatterTest do
  use EWallet.DBCase
  alias EWallet.TransactionFormatter
  alias EWalletDB.Account

  defp count_entries(formatted) do
    Enum.count(formatted["debits"]) + Enum.count(formatted["credits"])
  end

  defp has_entry?(formatted, type, address, amount, token) do
    entries =
      case type do
        :debit -> formatted["debits"]
        :credit -> formatted["credits"]
      end

    has_entry?(entries, address, amount, token)
  end

  defp has_entry?(entries, address, amount, token) do
    assert Enum.any?(entries, fn debit ->
             debit["address"] == address && debit["amount"] == amount &&
               debit["token"]["id"] == token.id
           end)
  end

  describe "format/1" do
    test "returns the expected format" do
      transaction = insert(:transaction)

      assert TransactionFormatter.format(transaction) ==
               %{
                 "idempotency_token" => transaction.idempotency_token,
                 "metadata" => transaction.metadata,
                 "debits" => [
                   %{
                     "address" => transaction.from_wallet.address,
                     "amount" => transaction.from_amount,
                     "token" => %{
                       "id" => transaction.from_token.id,
                       "metadata" => transaction.from_token.metadata
                     },
                     "metadata" => transaction.from_wallet.metadata
                   }
                 ],
                 "credits" => [
                   %{
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
          from_amount: 10000,
          from_token: omg,
          # To
          to_wallet: to_wallet,
          to_amount: 10000,
          to_token: omg
        )

      formatted = TransactionFormatter.format(transaction)

      assert has_entry?(formatted, :debit, from_wallet.address, 10000, omg)
      assert has_entry?(formatted, :credit, to_wallet.address, 10000, omg)
      assert count_entries(formatted) == 2
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
          from_amount: 10000,
          from_token: omg,
          to_wallet: to_wallet,
          to_amount: 10000,
          to_token: eth,
          exchange_account: exchange_account
        })

      formatted = TransactionFormatter.format(transaction)

      assert has_entry?(formatted, :debit, from_wallet.address, 10000, omg)
      assert has_entry?(formatted, :credit, exchange_wallet.address, 10000, omg)
      assert has_entry?(formatted, :debit, exchange_wallet.address, 10000, eth)
      assert has_entry?(formatted, :credit, to_wallet.address, 10000, eth)
      assert count_entries(formatted) == 4
    end
  end
end
