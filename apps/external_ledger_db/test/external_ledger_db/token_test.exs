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

defmodule ExternalLedgerDB.TokenTest do
  use ExUnit.Case, async: true
  import ExternalLedgerDB.Factory
  alias Ecto.Adapters.SQL
  alias Ecto.Adapters.SQL.Sandbox
  alias ExternalLedgerDB.{Repo, Token}

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  describe "initialization" do
    test "generates a UUID" do
      {res, token} = :token |> build |> Repo.insert()

      assert res == :ok
      assert String.match?(token.uuid, ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
    end

    test "generates the inserted_at and updated_at values" do
      {res, token} = :token |> build |> Repo.insert()

      assert res == :ok
      assert token.inserted_at != nil
      assert token.updated_at != nil
    end

    test "saves the encrypted metadata" do
      :token |> build() |> Repo.insert()

      {:ok, results} = SQL.query(Repo, "SELECT encrypted_metadata FROM token", [])

      row = Enum.at(results.rows, 0)
      assert <<1, 10, "AES.GCM.V1", _::binary>> = Enum.at(row, 0)
    end
  end

  describe "validations" do
    test "has a valid factory" do
      changeset = Token.changeset(%Token{}, string_params_for(:token))
      assert changeset.valid?
    end

    test "prevents creation of a token with an ID already in DB" do
      {:ok, inserted_token} = :token |> build |> Repo.insert()

      {:error, token} =
        %Token{}
        |> Token.changeset(string_params_for(:token, id: inserted_token.id))
        |> Repo.insert()

      assert token.errors == [
               id:
                 {"has already been taken",
                  [constraint: :unique, constraint_name: "token_id_index"]}
             ]
    end

    test "allows creation of a token with metadata" do
      {res, token} =
        :token
        |> build(%{metadata: %{e_id: "123"}})
        |> Repo.insert()

      assert res == :ok
      assert token.metadata == %{e_id: "123"}
    end
  end

  describe "validations for `adapter`" do
    test "accepts 'ethereum'" do
      params = string_params_for(:token, adapter: Token.ethereum())
      {res, token} = Token.insert(params)

      assert res == :ok
      assert token.adapter == Token.ethereum()
    end

    test "accepts 'omg_network'" do
      params = string_params_for(:token, adapter: Token.omg_network())
      {res, token} = Token.insert(params)

      assert res == :ok
      assert token.adapter == Token.omg_network()
    end

    test "rejects value other than 'ethereum' or 'omg_network'" do
      params = string_params_for(:token, adapter: "bitcoin")
      {res, changeset} = Token.insert(params)

      assert res == :error
      assert changeset.errors == [adapter: {"is invalid", [validation: :inclusion]}]
    end
  end

  describe "get/1" do
    test "returns the existing token by id" do
      {_, inserted} =
        :token
        |> build(%{id: "456"})
        |> Repo.insert()

      token = Token.get("456")
      assert token.uuid == inserted.uuid
    end

    test "returns nil if token does not exist" do
      token = Token.get("456")
      assert token == nil
    end
  end

  describe "get_or_insert/1" do
    test "inserts the token when it does not exist yet" do
      id = "123"
      refute Repo.get_by(Token, id: id)

      {:ok, _} =
        :token
        |> string_params_for(id: id)
        |> Token.get_or_insert()

      assert %Token{} = Repo.get_by(Token, id: id)
    end

    test "returns an existing token when it is already in the database" do
      id = "456"
      inserted_token = insert(:token, id: id)
      assert %Token{} = Repo.get_by(Token, id: id)

      {:ok, token} =
        Token.get_or_insert(%{
          "id" => "456"
        })

      assert inserted_token.uuid == token.uuid
    end

    defp start_task(pid, callback) do
      {:ok, pid} =
        Task.start_link(fn ->
          Sandbox.allow(Repo, pid, self())
          assert_receive :select_for_update, 5000
          token = callback.()
          assert token.id == "123"
          send(pid, :updated)
        end)

      pid
    end

    test "handles multiple inserts happening at the same time gracefully" do
      pid = self()

      callback = fn ->
        {:ok, token} =
          :token
          |> string_params_for(%{id: "123"})
          |> Token.get_or_insert()

        token
      end

      for _ <- 0..10, do: send(start_task(pid, callback), :select_for_update)

      {:ok, token} =
        :token
        |> string_params_for(%{id: "123"})
        |> Token.get_or_insert()

      assert_receive :updated, 5000
      assert length(Repo.all(Token)) == 1
      assert token.id == "123"
    end
  end

  describe "insert/1" do
    test "inserts a token if it does not exist" do
      params = string_params_for(:token)
      {:ok, token} = Token.insert(params)

      assert Repo.get_by(Token, id: params["id"]).uuid == token.uuid
    end

    test "returns the existing token without error if already exists" do
      {:ok, inserted_token} =
        :token
        |> string_params_for()
        |> Token.insert()

      assert Repo.get_by(Token, id: inserted_token.id)

      {res, token} =
        :token
        |> string_params_for(id: inserted_token.id)
        |> Token.insert()

      assert res == :ok
      assert inserted_token.uuid == token.uuid
    end

    test "returns errors when missing required fields" do
      {res, changeset} =
        %{
          id: nil,
          adapter: nil,
          contract_address: nil,
          metadata: nil,
          encrypted_metadata: nil
        }
        |> Token.insert()

      assert res == :error

      assert changeset.errors == [
               id: {"can't be blank", [validation: :required]},
               adapter: {"can't be blank", [validation: :required]},
               contract_address: {"can't be blank", [validation: :required]},
               metadata: {"can't be blank", [validation: :required]},
               encrypted_metadata: {"can't be blank", [validation: :required]}
             ]
    end
  end
end
