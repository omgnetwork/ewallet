# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule LocalLedgerDB.TransactionTest do
  use ExUnit.Case, async: true
  import LocalLedgerDB.Factory
  alias Ecto.Adapters.SQL
  alias Ecto.Adapters.SQL.Sandbox
  alias LocalLedgerDB.{Repo, Transaction}

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "generates a UUID" do
    {res, transaction} = :transaction |> build |> Repo.insert()

    assert res == :ok
    assert String.match?(transaction.uuid, ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
  end

  test "generates the inserted_at and updated_at values" do
    {res, transaction} = :transaction |> build |> Repo.insert()

    assert res == :ok
    assert transaction.inserted_at != nil
    assert transaction.updated_at != nil
  end

  test "prevents the creation of a transction without entries" do
    attrs = params_for(:transaction, entries: [])
    changeset = Transaction.changeset(%Transaction{}, attrs)

    refute changeset.valid?
  end

  test "allows creation of a transction with metadata" do
    {res, transaction} = :transaction |> build(%{metadata: %{e_id: "123"}}) |> Repo.insert()

    assert res == :ok
    assert transaction.metadata == %{e_id: "123"}
  end

  test "allows creation of a transction without metadata" do
    entries = [params_for(:entry)]
    attrs = params_for(:transaction, entries: entries)
    changeset = Transaction.changeset(%Transaction{}, attrs)

    assert changeset.valid?
  end

  test "saves the encrypted metadata" do
    :transaction |> build(%{metadata: %{e_id: "123"}}) |> Repo.insert()

    {:ok, results} = SQL.query(Repo, "SELECT encrypted_metadata FROM transaction", [])

    row = Enum.at(results.rows, 0)
    assert <<1, 10, "AES.GCM.V1", _::binary>> = Enum.at(row, 0)
  end
end
