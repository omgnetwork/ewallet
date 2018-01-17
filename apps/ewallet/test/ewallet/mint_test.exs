defmodule EWallet.MintTest do
  use ExUnit.Case
  import EWalletDB.Factory
  import Mock
  alias EWallet.Mint
  alias EWalletMQ.Publishers.Entry
  alias EWalletDB.{MintedToken, Repo, Account}
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID

  setup do
    :ok = Sandbox.checkout(Repo)
    {:ok, _} = Account.insert(%{name: "Master", master: true})
    :ok
  end

  describe "insert/2" do
    test "inserts a new confirmed mint" do
      with_mock Entry,
        [genesis: fn _data, _idempotency_token ->
          {:ok, %{data: "from ledger"}}
        end] do
          {:ok, minted_token} = MintedToken.insert(params_for(:minted_token))

          {res, mint, transfer} = Mint.insert(%{
            "idempotency_token" => UUID.generate(),
            "token_id" => minted_token.friendly_id,
            "amount" => 100_000,
            "description" => "description",
            "metadata" => %{},
          })

          assert res == :ok
          assert mint != nil
          assert mint.confirmed == true
          assert transfer.ledger_response == %{"data" => "from ledger"}
      end
    end

    test "inserts an unconfirmed mint if the transaction didn't go through" do
      with_mock Entry,
        [genesis: fn _data, _idempotency_token ->
          {:error, "error", "description"}
        end] do
          {:ok, minted_token} = MintedToken.insert(params_for(:minted_token))

          {res, error, _description, mint} = Mint.insert(%{
            "idempotency_token" => UUID.generate(),
            "token_id" => minted_token.friendly_id,
            "amount" => 100_000,
            "description" => "description",
            "metadata" => %{},
          })

          assert res == :error
          assert mint.confirmed == false
          assert error == "error"
      end
    end

    test "fails to insert a new mint when the data is invalid" do
      with_mock Entry,
        [genesis: fn _data, _idempotency_token ->
          {:ok, %{data: "from ledger"}}
        end] do
          {:ok, minted_token} = MintedToken.insert(params_for(:minted_token))

          {res, changeset} = Mint.insert(%{
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
end
