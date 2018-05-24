defmodule EWallet.MintGateTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.MintGate
  alias EWalletDB.Token
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID

  describe "insert/2" do
    test "inserts a new confirmed mint" do
      {:ok, btc} = :token |> params_for(symbol: "BTC") |> Token.insert()

      {res, mint, transfer} =
        MintGate.insert(%{
          "idempotency_token" => UUID.generate(),
          "token_id" => btc.id,
          "amount" => 10_000 * btc.subunit_to_unit,
          "description" => "Minting 10_000 #{btc.symbol}",
          "metadata" => %{}
        })

      assert res == :ok
      assert mint != nil
      assert mint.confirmed == true
      assert transfer.status == "confirmed"
    end

    test "fails to insert a new mint when the data is invalid" do
      {:ok, token} = Token.insert(params_for(:token))

      {res, changeset} =
        MintGate.insert(%{
          "idempotency_token" => UUID.generate(),
          "token_id" => token.id,
          "amount" => nil,
          "description" => "description",
          "metadata" => %{}
        })

      assert res == :error

      assert changeset.errors == [
               amount: {"can't be blank", [validation: :required]}
             ]
    end
  end
end
