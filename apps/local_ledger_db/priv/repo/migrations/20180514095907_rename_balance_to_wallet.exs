defmodule LocalLedgerDB.Repo.Migrations.RenameBalanceToWallet do
  use Ecto.Migration

  def change do
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

    # tables = [:cached_balance, :transaction]
    #
    # rename table(:balance), to: table(:wallet)
    #
    # Enum.each(tables, fn table ->
    #   rename table(table), :balance_address, to: :wallet_address
    #   drop constraint(table, "#{Atom.to_string(table)}_balance_address_fkey")
    # end)
    #
    # drop index(:balance, [:address])
    # create unique_index(:wallet, [:address])
    #
    # Enum.each(tables, fn table ->
    #   alter table(table) do
    #     modify :wallet_address, references(:wallet, type: :string,
    #                                         column: :address), null: false
    #   end
    # end)
  end
end
