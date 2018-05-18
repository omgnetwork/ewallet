defmodule EWalletDB.Repo.Migrations.RenameWalletToWallet do
  use Ecto.Migration

  def change do
    drop constraint(:transaction_consumption, "transaction_request_consumption_balance_address_fkey")
    alter table(:transaction_consumption) do
      modify :balance_address, references(:balance, type: :string,
                                          column: :address), null: false
    end

    tables = %{
      transaction_consumption: %{balance_address: :wallet_address},
      transaction_request: %{balance_address: :wallet_address},
      transfer: %{to: :to, from: :from},
    }

    rename table(:balance), to: table(:wallet)
    Enum.each(tables, fn {table, columns} ->
      Enum.each(columns, fn {old_name, new_name} ->
        if old_name != new_name, do: rename table(table), old_name, to: new_name
        drop constraint(table, "#{Atom.to_string(table)}_#{Atom.to_string(old_name)}_fkey")
      end)
    end)

    drop_if_exists index(:balance, [:address])
    drop_if_exists index(:balance, [:account_id, :name])
    drop_if_exists index(:balance, [:account_id, :identifier])
    drop_if_exists index(:balance, [:user_id, :name])
    drop_if_exists index(:balance, [:user_id, :identifier])

    create unique_index(:wallet, [:address])
    create unique_index(:wallet, [:account_uuid, :name])
    create unique_index(:wallet, [:account_uuid, :identifier])
    create unique_index(:wallet, [:user_uuid, :name])
    create unique_index(:wallet, [:user_uuid, :identifier])

    Enum.each(tables, fn {table, columns} ->
      Enum.each(columns, fn {_old_name, new_name} ->
        alter table(table) do
          modify new_name, references(:wallet, type: :string,
                                      column: :address), null: false
        end
      end)
    end)
  end
end
