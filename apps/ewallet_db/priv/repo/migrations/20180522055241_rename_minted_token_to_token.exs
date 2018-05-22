defmodule EWalletDB.Repo.Migrations.RenameMintedTokenToToken do
  use Ecto.Migration

  def up do
    tables = %{
      mint: %{minted_token_uuid: :token_uuid},
      transfer: %{minted_token_uuid: :token_uuid},
      transaction_request: %{minted_token_uuid: :token_uuid},
      transaction_consumption: %{minted_token_uuid: :token_uuid},
      wallet: %{minted_token_uuid: :token_uuid},
    }

    # Fix invalid constraint name for mint, transfer, transaction_request
    # {table}_minted_token_id_fkey -> {table}_minted_token_uuid_fkey
    each(tables, fn table, old_name, _new_name ->
      up_regenerate_constraint(table, old_name)
    end)

    # Rename minted token table to token
    rename table(:minted_token), to: table(:token)

    # Remove constraint minted_token_account_id_fkey in token table
    # Rename to token_account_uuid_fkey
    drop constraint(:token, "minted_token_account_id_fkey")
    alter table(:token) do
      modify :account_uuid, references(:account, type: :uuid,
                                       column: :uuid), null: false
    end

    # Rename column from minted_token_uuid -> token_uuid
    each(tables, fn table, old_name, new_name ->
      drop constraint(table, "#{Atom.to_string(table)}_#{Atom.to_string(old_name)}_fkey")
      rename table(table), old_name, to: new_name
    end)

    # Recreate id index for token table
    drop index(:minted_token, [:id])
    create unique_index(:token, [:id])
    drop index(:minted_token, :symbol)
    drop index(:minted_token, :iso_code)
    drop index(:minted_token, :name)
    create index(:token, :symbol)

    # Regenerate foreign keys for token_uuid columns
    each(tables, fn table, _old_name, new_name ->
      modify_column(table, new_name, table == :wallet)
    end)
  end

  def down do
    tables = %{
      mint: %{minted_token_uuid: :token_uuid},
      transfer: %{minted_token_uuid: :token_uuid},
      transaction_request: %{minted_token_uuid: :token_uuid},
      transaction_consumption: %{minted_token_uuid: :token_uuid},
      wallet: %{minted_token_uuid: :token_uuid},
    }

    rename table(:token), to: table(:minted_token)

    drop constraint(:minted_token, "token_account_uuid_fkey")
    alter table(:minted_token) do
      modify :account_uuid, references(:account, type: :uuid,
                                       column: :uuid, name: "minted_token_account_id_fkey"),
                                       null: false
    end

    each(tables, fn table, old_name, new_name ->
      down_regenerate_constraint(table, old_name, new_name)
    end)

    drop index(:token, [:id])
    drop index(:token, [:symbol])
    create unique_index(:minted_token, [:id])
    create unique_index(:minted_token, :symbol)
    create unique_index(:minted_token, :iso_code)
    create unique_index(:minted_token, :name)
  end

  defp each(tables, func) do
    Enum.each(tables, fn {table, columns} ->
      Enum.each(columns, fn {old_name, new_name} ->
        func.(table, old_name, new_name)
      end)
    end)
  end

  defp up_regenerate_constraint(:transaction_consumption, _old_name) do
    # Fix transaction_request_consumption -> transaction_consumption
    # drop constraint(:transaction_consumption, "transaction_consumption_minted_token_id_fkey")
    drop constraint(:transaction_consumption, "transaction_request_consumption_minted_token_id_fkey")
    alter table(:transaction_consumption) do
      # constraint is now transaction_consumption_minted_token_uuid_fkey
      modify :minted_token_uuid, references(:minted_token, type: :uuid,
                                            column: :uuid), null: false
    end
  end
  defp up_regenerate_constraint(:wallet, _old_name) do
    # Fix invalid constraint balance_minted_token_id_fkey -> wallet_minted_token_uuid_fkey
    # drop constraint(:wallet, "wallet_minted_token_id_fkey")
    drop constraint(:wallet, "balance_minted_token_id_fkey")
    alter table(:wallet) do
      modify :minted_token_uuid, references(:minted_token, type: :uuid,
                                            column: :uuid), null: true
    end
  end
  defp up_regenerate_constraint(table, old_name) do
    drop constraint(table, "#{Atom.to_string(table)}_minted_token_id_fkey")
    alter table(table) do
      modify old_name, references(:minted_token, type: :uuid,
                                  column: :uuid), null: false
    end
  end

  defp down_regenerate_constraint(:transaction_consumption = table, old_name, new_name) do
    drop constraint(table, "#{Atom.to_string(table)}_#{Atom.to_string(new_name)}_fkey")
    rename table(table), new_name, to: old_name
    alter table(table) do
      modify old_name, references(:minted_token, type: :uuid,
                                  column: :uuid, name: "transaction_request_consumption_minted_token_id_fkey"),
                                  null: false
    end
  end
  defp down_regenerate_constraint(:wallet = table, old_name, new_name) do
    drop constraint(table, "#{Atom.to_string(table)}_#{Atom.to_string(new_name)}_fkey")
    rename table(table), new_name, to: old_name
    alter table(table) do
      modify old_name, references(:minted_token, type: :uuid,
                                  column: :uuid, name: "balance_minted_token_id_fkey"),
                                  null: true
    end
  end
  defp down_regenerate_constraint(table, old_name, new_name) do
    drop constraint(table, "#{Atom.to_string(table)}_#{Atom.to_string(new_name)}_fkey")
    rename table(table), new_name, to: old_name
    alter table(table) do
      modify old_name, references(:minted_token, type: :uuid,
                                  column: :uuid, name: "#{Atom.to_string(table)}_minted_token_id_fkey"),
                                  null: false
    end
  end

  defp modify_column(table, name, null) do
    alter table(table) do
      modify name, references(:token, type: :uuid,
                               column: :uuid), null: null
    end
  end
end
