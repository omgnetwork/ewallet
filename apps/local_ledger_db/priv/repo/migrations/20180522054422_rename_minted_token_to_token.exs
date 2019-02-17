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

defmodule LocalLedgerDB.Repo.Migrations.RenameMintedTokenToToken do
  use Ecto.Migration

  def up do
    tables = %{
      transaction: %{minted_token_id: :token_id},
    }

    rename table(:minted_token), to: table(:token)

    Enum.each(tables, fn {table, columns} ->
      Enum.each(columns, fn {old_name, new_name} ->
        rename table(table), old_name, to: new_name
        drop constraint(table, "#{Atom.to_string(table)}_#{Atom.to_string(old_name)}_fkey")
      end)
    end)

    drop index(:minted_token, [:id])
    create unique_index(:token, [:id])

    Enum.each(tables, fn {table, columns} ->
      Enum.each(columns, fn {_old_name, new_name} ->
        alter table(table) do
          modify new_name, references(:token, type: :string,
                                      column: :id), null: false
        end
      end)
    end)
  end

  def down do
    tables = %{
      transaction: %{minted_token_id: :token_id},
    }

    rename table(:token), to: table(:minted_token)

    Enum.each(tables, fn {table, columns} ->
      Enum.each(columns, fn {old_name, new_name} ->
        rename table(table), new_name, to: old_name
        drop constraint(table, "#{Atom.to_string(table)}_#{Atom.to_string(new_name)}_fkey")
      end)
    end)

    drop index(:token, [:id])
    create unique_index(:minted_token, [:id])

    Enum.each(tables, fn {table, columns} ->
      Enum.each(columns, fn {old_name, _new_name} ->
        alter table(table) do
          modify old_name, references(:minted_token, type: :string,
                                      column: :id), null: false
        end
      end)
    end)
  end
end
