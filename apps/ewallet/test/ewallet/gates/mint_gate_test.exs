defmodule EWallet.MintGateTest do
  use EWallet.LocalLedgerCase, async: true
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID
  alias EWallet.MintGate
  alias EWalletDB.Token
  alias ActivityLogger.System

  describe "insert/2" do
    test "inserts a new confirmed mint" do
      {:ok, btc} = :token |> params_for(symbol: "BTC") |> Token.insert()

      {res, mint, transaction} =
        MintGate.insert(%{
          "idempotency_token" => UUID.generate(),
          "token_id" => btc.id,
          "amount" => 10_000 * btc.subunit_to_unit,
          "description" => "Minting 10_000 #{btc.symbol}",
          "metadata" => %{},
          "originator" => %System{}
        })

      assert res == :ok
      assert mint != nil
      assert mint.confirmed == true
      assert transaction.status == "confirmed"
    end

    test "inserts a new confirmed mint with big number" do
      {:ok, btc} = :token |> params_for(symbol: "BTC") |> Token.insert()

      {res, mint, transaction} =
        MintGate.insert(%{
          "idempotency_token" => UUID.generate(),
          "token_id" => btc.id,
          "amount" => 100_000_000_000_000_000_000_000_000_000_000_000 - 1,
          "description" => "Minting 10_000 #{btc.symbol}",
          "metadata" => %{},
          "originator" => %System{}
        })

      assert res == :ok
      assert mint != nil
      assert mint.confirmed == true
      assert mint.amount == 100_000_000_000_000_000_000_000_000_000_000_000 - 1
      assert transaction.status == "confirmed"
    end

    test "fails to insert a new mint when the data is invalid" do
      {:ok, token} = Token.insert(params_for(:token))

      {res, changeset} =
        MintGate.insert(%{
          "idempotency_token" => UUID.generate(),
          "token_id" => token.id,
          "amount" => nil,
          "description" => "description",
          "metadata" => %{},
          "originator" => %System{}
        })

      assert res == :error

      assert changeset.errors == [
               amount: {"can't be blank", [validation: :required]}
             ]
    end
  end
end
