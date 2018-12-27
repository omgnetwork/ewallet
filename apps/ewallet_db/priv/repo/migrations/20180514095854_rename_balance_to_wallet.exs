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

defmodule EWalletDB.Repo.Migrations.RenameBalanceToWallet do
  use Ecto.Migration

  def up do
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
        drop_constraint(table, old_name, new_name)
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

  def down do
    tables = %{
      transaction_consumption: %{balance_address: :wallet_address},
      transaction_request: %{balance_address: :wallet_address},
      transfer: %{to: :to, from: :from},
    }

    rename table(:wallet), to: table(:balance)

    Enum.each(tables, fn {table, columns} ->
      Enum.each(columns, fn {old_name, new_name} ->
        drop_constraint(table, new_name, old_name)
      end)
    end)

    drop index(:wallet, [:address])
    drop index(:wallet, [:account_uuid, :name])
    drop index(:wallet, [:account_uuid, :identifier])
    drop index(:wallet, [:user_uuid, :name])
    drop index(:wallet, [:user_uuid, :identifier])

    create unique_index(:balance, [:address])
    create unique_index(:balance, [:account_uuid, :name])
    create unique_index(:balance, [:account_uuid, :identifier])
    create unique_index(:balance, [:user_uuid, :name])
    create unique_index(:balance, [:user_uuid, :identifier])

    Enum.each(tables, fn {table, columns} ->
      Enum.each(columns, fn {old_name, _new_name} ->
        alter table(table) do
          modify old_name, references(:balance, type: :string,
                                      column: :address), null: false
        end
      end)
    end)

    drop constraint(:transaction_consumption, "transaction_consumption_balance_address_fkey")
    alter table(:transaction_consumption) do
      modify :balance_address, references(:balance, type: :string,
                                          column: :address, name: "transaction_request_consumption_balance_address_fkey"),
                                          null: false
    end
  end

  def drop_constraint(table, old_name, new_name) when old_name == new_name do
    drop constraint(table, "#{Atom.to_string(table)}_#{Atom.to_string(old_name)}_fkey")
  end

  def drop_constraint(table, old_name, new_name) do
    rename table(table), old_name, to: new_name
    drop constraint(table, "#{Atom.to_string(table)}_#{Atom.to_string(old_name)}_fkey")
  end
end
