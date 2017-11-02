defmodule Kubera.MintTest do
  use ExUnit.Case
  import KuberaDB.Factory
  import Mock
  alias Kubera.Mint
  alias KuberaMQ.Entry
  alias KuberaDB.{MintedToken, Repo}
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "insert/2" do
    test "inserts a new confirmed mint" do
      with_mock Entry,
        [genesis: fn _data, callback ->
          callback.({:ok, %{data: "from ledger"}})
        end] do
          {:ok, minted_token} = MintedToken.insert(params_for(:minted_token))

          Mint.insert(%{
            minted_token: minted_token,
            amount: 100_000,
            description: "description",
            metadata: %{},
          }, fn {res, mint, data} ->
            assert res == :ok
            assert mint != nil
            assert mint.confirmed == true
            assert data == %{data: "from ledger"}
          end)
      end
    end

    test "inserts an unconfirmed mint if the transaction didn't go through" do
      with_mock Entry,
        [genesis: fn _data, callback ->
          callback.({:error, "error", "description"})
        end] do
          {:ok, minted_token} = MintedToken.insert(params_for(:minted_token))

          Mint.insert(%{
            minted_token: minted_token,
            amount: 100_000,
            description: "description",
            metadata: %{},
          }, fn {res, mint, error, _description} ->
            assert res == :error
            assert mint.confirmed == false
            assert error == "error"
          end)
      end
    end

    test "fails to insert a new mint when the data is invalid" do
      with_mock Entry,
        [genesis: fn _data, callback ->
          callback.({:ok, %{data: "from ledger"}})
        end] do
          {:ok, minted_token} = MintedToken.insert(params_for(:minted_token))

          Mint.insert(%{
            minted_token: minted_token,
            amount: nil,
            description: "description",
            metadata: %{},
          }, fn {res, changeset, nil} ->
            assert res == :error
            assert changeset.errors == [
              amount: {"can't be blank", [validation: :required]}
            ]
          end)
      end
    end
  end
end
