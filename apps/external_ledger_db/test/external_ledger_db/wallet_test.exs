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

defmodule ExternalLedgerDB.WalletTest do
  use ExUnit.Case, async: true
  import ExternalLedgerDB.Factory
  alias Ecto.Adapters.SQL
  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.UUID
  alias ExternalLedgerDB.{Repo, Wallet}

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "initialization" do
    test "generates a UUID" do
      {res, wallet} = :wallet |> build |> Repo.insert()

      assert res == :ok
      assert String.match?(wallet.uuid, ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
    end

    test "generates the inserted_at and updated_at values" do
      {res, wallet} = :wallet |> build |> Repo.insert()

      assert res == :ok
      assert wallet.inserted_at != nil
      assert wallet.updated_at != nil
    end

    test "saves the encrypted metadata" do
      :wallet |> build() |> Repo.insert()

      {:ok, results} = SQL.query(Repo, "SELECT encrypted_metadata FROM wallet", [])

      row = Enum.at(results.rows, 0)
      assert <<1, 10, "AES.GCM.V1", _::binary>> = Enum.at(row, 0)
    end
  end

  describe "validations" do
    test "has a valid factory" do
      changeset = Wallet.changeset(%Wallet{}, string_params_for(:wallet))
      assert changeset.valid?
    end

    test "prevents creation of a wallet without an address" do
      params = string_params_for(:wallet, %{address: nil})
      changeset = Wallet.changeset(%Wallet{}, params)
      refute changeset.valid?
      assert changeset.errors == [address: {"can't be blank", [validation: :required]}]
    end

    test "prevents creation of a wallet with an address already in DB" do
      {:ok, inserted_wallet} = :wallet |> build |> Repo.insert()

      {:error, wallet} =
        %Wallet{}
        |> Wallet.changeset(string_params_for(:wallet, address: inserted_wallet.address))
        |> Repo.insert()

      assert wallet.errors == [
               address:
                 {"has already been taken",
                  [constraint: :unique, constraint_name: "wallet_address_index"]}
             ]
    end

    test "allows creation of a wallet with metadata" do
      {res, wallet} =
        :wallet
        |> build(%{metadata: %{e_id: "123"}})
        |> Repo.insert()

      assert res == :ok
      assert wallet.metadata == %{e_id: "123"}
    end

    test "returns errors when missing required fields" do
      {res, changeset} =
        %{
          address: nil,
          adapter: nil,
          primary: nil,
          type: nil,
          public_key: nil,
          metadata: nil,
          encrypted_metadata: nil
        }
        |> Wallet.insert()

      assert res == :error

      assert changeset.errors == [
               address: {"can't be blank", [validation: :required]},
               adapter: {"can't be blank", [validation: :required]},
               primary: {"can't be blank", [validation: :required]},
               type: {"can't be blank", [validation: :required]},
               public_key: {"can't be blank", [validation: :required]},
               metadata: {"can't be blank", [validation: :required]},
               encrypted_metadata: {"can't be blank", [validation: :required]}
             ]
    end
  end

  describe "validations for `adapter`" do
    test "accepts 'ethereum'" do
      params = string_params_for(:wallet, adapter: Wallet.ethereum())
      {res, wallet} = Wallet.insert(params)

      assert res == :ok
      assert wallet.adapter == Wallet.ethereum()
    end

    test "accepts 'omg_network'" do
      params = string_params_for(:wallet, adapter: Wallet.omg_network())
      {res, wallet} = Wallet.insert(params)

      assert res == :ok
      assert wallet.adapter == Wallet.omg_network()
    end

    test "rejects value other than 'ethereum' or 'omg_network'" do
      params = string_params_for(:wallet, adapter: "bitcoin")
      {res, changeset} = Wallet.insert(params)

      assert res == :error
      assert changeset.errors == [adapter: {"is invalid", [validation: :inclusion]}]
    end
  end

  describe "validations for `type`" do
    test "accepts 'hot'" do
      params = string_params_for(:wallet, type: Wallet.hot())
      {res, wallet} = Wallet.insert(params)

      assert res == :ok
      assert wallet.type == Wallet.hot()
    end

    test "accepts 'cold'" do
      params = string_params_for(:wallet, type: Wallet.cold())
      {res, wallet} = Wallet.insert(params)

      assert res == :ok
      assert wallet.type == Wallet.cold()
    end

    test "rejects value other than 'hot' or 'cold'" do
      params = string_params_for(:wallet, type: "warm")
      {res, changeset} = Wallet.insert(params)

      assert res == :error
      assert changeset.errors == [type: {"is invalid", [validation: :inclusion]}]
    end
  end

  describe "all/1" do
    test "retrieves all wallets matching the given addresses" do
      wallet_1 = insert(:wallet, address: "address_1")
      _wallet_2 = insert(:wallet, address: "address_2")
      wallet_3 = insert(:wallet, address: "address_3")
      _wallet_4 = insert(:wallet, address: "address_4")

      wallets = Wallet.all([wallet_1.address, wallet_3.address])
      uuids = Enum.map(wallets, fn w -> w.uuid end)

      assert length(wallets) == 2
      assert Enum.member?(uuids, wallet_1.uuid)
      assert Enum.member?(uuids, wallet_3.uuid)
    end
  end

  describe "get/1" do
    test "returns the existing wallet by address" do
      {_, inserted} =
        :wallet
        |> build(%{address: "456"})
        |> Repo.insert()

      wallet = Wallet.get("456")
      assert wallet.uuid == inserted.uuid
    end

    test "returns nil if wallet does not exist" do
      wallet = Wallet.get("456")
      assert wallet == nil
    end
  end

  describe "get_by/1" do
    test "returns the existing wallet by various fields" do
      [_, inserted, _] = insert_list(3, :wallet)

      assert Wallet.get_by(uuid: inserted.uuid).uuid == inserted.uuid
      assert Wallet.get_by(address: inserted.address).uuid == inserted.uuid
    end

    test "returns nil if the value cannot be found" do
      [_, _, _] = insert_list(3, :wallet)

      assert Wallet.get_by(uuid: UUID.generate()) == nil
      assert Wallet.get_by(address: "not_valid") == nil
    end
  end

  describe "get_or_insert/1" do
    test "inserts the wallet when it does not exist yet" do
      address = "123"
      refute Repo.get_by(Wallet, address: address)

      {:ok, _} =
        :wallet
        |> string_params_for(address: address)
        |> Wallet.get_or_insert()

      assert %Wallet{} = Repo.get_by(Wallet, address: address)
    end

    test "returns an existing wallet when it is already in the database" do
      address = "456"
      inserted_wallet = insert(:wallet, address: address)
      assert %Wallet{} = Repo.get_by(Wallet, address: address)

      {:ok, wallet} =
        Wallet.get_or_insert(%{
          "address" => "456"
        })

      assert inserted_wallet.uuid == wallet.uuid
    end

    defp start_task(pid, callback) do
      {:ok, pid} =
        Task.start_link(fn ->
          Sandbox.allow(Repo, pid, self())
          assert_receive :select_for_update, 5000
          wallet = callback.()
          assert wallet.address == "123"
          send(pid, :updated)
        end)

      pid
    end

    test "handles multiple inserts happening at the same time gracefully" do
      pid = self()

      callback = fn ->
        {:ok, wallet} =
          :wallet
          |> string_params_for(%{address: "123"})
          |> Wallet.get_or_insert()

        wallet
      end

      for _ <- 0..10, do: send(start_task(pid, callback), :select_for_update)

      {:ok, wallet} =
        :wallet
        |> string_params_for(%{address: "123"})
        |> Wallet.get_or_insert()

      assert_receive :updated, 5000
      assert length(Repo.all(Wallet)) == 1
      assert wallet.address == "123"
    end
  end

  describe "insert/1" do
    test "inserts a wallet if it does not exist" do
      params = string_params_for(:wallet)
      {:ok, wallet} = Wallet.insert(params)

      assert Repo.get_by(Wallet, address: params["address"]).uuid == wallet.uuid
    end

    test "returns the existing wallet without error if already exists" do
      {:ok, inserted_wallet} =
        :wallet
        |> string_params_for()
        |> Wallet.insert()

      assert Repo.get_by(Wallet, address: inserted_wallet.address)

      {res, wallet} =
        :wallet
        |> string_params_for(address: inserted_wallet.address)
        |> Wallet.insert()

      assert res == :ok
      assert inserted_wallet.uuid == wallet.uuid
    end

    test "returns an error when passing invalid arguments" do
      assert Repo.all(Wallet) == []

      {res, changeset} =
        :wallet
        |> params_for(address: nil)
        |> Wallet.insert()

      assert res == :error
      assert changeset.errors == [address: {"can't be blank", [validation: :required]}]
    end
  end

  describe "touch/1" do
    test "touches a wallet" do
      wallet = insert(:wallet)

      _ = Wallet.touch(wallet.address)

      touched = Wallet.get(wallet.address)
      assert NaiveDateTime.compare(touched.updated_at, wallet.updated_at) == :gt
    end

    test "touches multiple wallets" do
      wallets = insert_list(3, :wallet)

      {3, _} =
        wallets
        |> Enum.map(fn w -> w.address end)
        |> Wallet.touch()

      _ =
        Enum.each(wallets, fn wallet ->
          touched = Wallet.get(wallet.address)
          assert NaiveDateTime.compare(touched.updated_at, wallet.updated_at) == :gt
        end)
    end
  end

  describe "lock/1" do
    test "locks the wallets associated with the given addresses get locked" do
      {_, wallet_1} = :wallet |> build(%{address: "123"}) |> Repo.insert()
      {_, wallet_2} = :wallet |> build(%{address: "345"}) |> Repo.insert()
      pid = self()

      {:ok, new_pid} =
        Task.start_link(fn ->
          Sandbox.allow(Repo, pid, self())
          assert_receive :select_for_update, 5000

          Repo.transaction(fn ->
            # this should block until the other entry commit
            wallet = Wallet.get(wallet_1.address)
            changeset = Wallet.changeset(wallet, %{metadata: %{desc: "Blocked"}})
            Repo.update!(changeset)
          end)

          send(pid, :updated)
        end)

      {:ok, updated_wallet} =
        Repo.transaction(fn ->
          Wallet.lock([wallet_1.address, wallet_2.address])
          send(new_pid, :select_for_update)

          wallet_1.address
          |> Wallet.get()
          |> Wallet.changeset(%{metadata: %{desc: "Free"}})
          |> Repo.update!()

          Wallet.get(wallet_1.address)
        end)

      assert updated_wallet.metadata == %{"desc" => "Free"}
      assert_receive :updated, 5000
      assert Wallet.get(wallet_1.address).metadata == %{"desc" => "Blocked"}
    end
  end
end
