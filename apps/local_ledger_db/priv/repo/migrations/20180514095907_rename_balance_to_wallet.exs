defmodule LocalLedgerDB.Repo.Migrations.RenameBalanceToWallet do
  use Ecto.Migration

  def up do
    tables = %{
      cached_balance: %{balance_address: :wallet_address},
      transaction: %{balance_address: :wallet_address}
    }

    rename table(:balance), to: table(:wallet)

    Enum.each(tables, fn {table, columns} ->
      Enum.each(columns, fn {old_name, new_name} ->
        rename table(table), old_name, to: new_name
        drop constraint(table, "#{Atom.to_string(table)}_#{Atom.to_string(old_name)}_fkey")
      end)
    end)

    drop index(:balance, [:address])
    create unique_index(:wallet, [:address])

    Enum.each(tables, fn {table, columns} ->
      Enum.each(columns, fn {_old_name, new_name} ->
        alter table(table) do
          modify new_name, references(:wallet, type: :string,
                                      column: :address), null: false
        end
      end)
    end)
  end

  def down do
    tables = %{
      cached_balance: %{balance_address: :wallet_address},
      transaction: %{balance_address: :wallet_address}
    }

    rename table(:wallet), to: table(:balance)

    Enum.each(tables, fn {table, columns} ->
      Enum.each(columns, fn {old_name, new_name} ->
        drop constraint(table, "#{Atom.to_string(table)}_#{Atom.to_string(new_name)}_fkey")
        rename table(table), new_name, to: old_name
      end)
    end)

    drop index(:wallet, [:address])
    create unique_index(:balance, [:address])

    Enum.each(tables, fn {table, columns} ->
      Enum.each(columns, fn {old_name, _new_name} ->
        alter table(table) do
          modify old_name, references(:balance, type: :string,
                                      column: :address), null: false
        end
      end)
    end)
  end
end
