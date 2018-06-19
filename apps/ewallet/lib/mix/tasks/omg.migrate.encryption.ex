defmodule Mix.Tasks.Omg.Migrate.Encryption do
  @moduledoc """
  Temporary task for migrating encryption scheme to AES-GCM.

  ## Examples

  Simply run the following command:

      mix omg.migrate.encryption
  """

  import Ecto.Query

  alias Ecto.Changeset

  @start_apps [:logger, :crypto, :ssl, :postgrex, :ecto, :cloak]
  @migration_spec [
    ewallet_db: [
      EWalletDB.Repo,
      [
        EWalletDB.Account,
        EWalletDB.Token,
        EWalletDB.TransactionConsumption,
        EWalletDB.TransactionRequest,
        EWalletDB.Transfer,
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
    Enum.each(@start_apps, &Application.ensure_all_started/1)
    Logger.configure(level: :info)

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
