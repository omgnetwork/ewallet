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

defmodule Mix.Tasks.Omg.Migrate.Encryption do
  @moduledoc """
  Temporary task for migrating encryption scheme to AES-GCM.

  ## Examples

  Simply run the following command:

      mix omg.migrate.encryption
  """

  import Ecto.Query
  alias Ecto.Changeset
  alias EWallet.CLI

  @start_apps [:logger, :crypto, :ssl, :postgrex, :ecto, :cloak]
  @migration_spec [
    ewallet_db: [
      EWalletDB.Repo,
      [
        EWalletDB.Account,
        EWalletDB.Token,
        EWalletDB.TransactionConsumption,
        EWalletDB.TransactionRequest,
        EWalletDB.Transaction,
        EWalletDB.User,
        EWalletDB.Wallet
      ]
    ],
    local_ledger_db: [
      LocalLedgerDB.Repo,
      [
        LocalLedgerDB.Entry,
        LocalLedgerDB.Token,
        LocalLedgerDB.Wallet
      ]
    ]
  ]

  def run(_args) do
    _ = CLI.configure_logger()

    Enum.each(@start_apps, &Application.ensure_all_started/1)

    Enum.each(@migration_spec, fn {app_name, [repo, schemas]} ->
      {:ok, _} = Application.ensure_all_started(app_name)
      migrate(schemas, repo)
    end)
  end

  #
  # Migration
  #

  defp migrate([], _), do: nil

  defp migrate([schema | t], repo) do
    fields = cloak_fields(schema)

    schema
    |> repo.all()
    |> migrate_each(repo, schema, fields)

    migrate(t, repo)
  end

  defp migrate_each([], _, _, _), do: nil

  defp migrate_each([record | t], repo, schema, fields) do
    table_name = schema.__schema__(:source)
    uuid = record.uuid

    repo.transaction(fn ->
      query =
        schema
        |> where(uuid: ^uuid)
        |> lock("FOR UPDATE")

      case repo.one(query) do
        nil ->
          :noop

        row ->
          IO.puts("Updating #{table_name} #{uuid}...")

          row
          |> force_changes(fields)
          |> repo.update()
      end
    end)

    migrate_each(t, repo, schema, fields)
  end

  defp force_changes(row, fields) do
    Enum.reduce(fields, Changeset.change(row), fn field, changeset ->
      Changeset.force_change(changeset, field, Map.get(row, field))
    end)
  end

  #
  # Cloak
  #

  defp cloak_fields(schema) do
    :fields
    |> schema.__schema__()
    |> cloak_fields(schema, [])
  end

  defp cloak_fields([], _, acc), do: acc

  defp cloak_fields([field | t], schema, acc) do
    type = schema.__schema__(:type, field)

    acc =
      case Code.ensure_loaded?(type) && function_exported?(type, :__cloak__, 0) do
        true -> acc ++ [field]
        _ -> acc
      end

    cloak_fields(t, schema, acc)
  end
end
