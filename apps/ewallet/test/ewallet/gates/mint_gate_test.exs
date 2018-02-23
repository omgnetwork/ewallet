defmodule EWallet.MintGateTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.MintGate
  alias EWalletDB.MintedToken
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID

  describe "insert/2" do
    test "inserts a new confirmed mint" do
      {:ok, btc} = :minted_token |> params_for(symbol: "BTC") |> MintedToken.insert()

      {res, mint, transfer} = MintGate.insert(%{
        "idempotency_token" => UUID.generate(),
        "token_id" => btc.friendly_id,
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
      {:ok, minted_token} = MintedToken.insert(params_for(:minted_token))

      {res, changeset} = MintGate.insert(%{
        "idempotency_token" => UUID.generate(),
        "token_id" => minted_token.friendly_id,
        "amount" => nil,
        "description" => "description",
        "metadata" => %{},
      })
      assert res == :error
      assert changeset.errors == [
        amount: {"can't be blank", [validation: :required]}
      ]
    end
  end
end
