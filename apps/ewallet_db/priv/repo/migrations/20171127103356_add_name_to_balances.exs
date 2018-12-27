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

defmodule EWalletDB.Repo.Migrations.AddNameToBalances do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  def up do
    alter table(:balance) do
      add :name, :string
      add :identifier, :string
    end

    flush()

    migrate_up(true)
    migrate_up(false)

    alter table(:balance) do
      modify :name, :string, null: false
      modify :identifier, :string, null: false
      remove :genesis
    end

    create unique_index(:balance, [:account_id, :name])
    create unique_index(:balance, [:account_id, :identifier])
    create unique_index(:balance, [:user_id, :name])
    create unique_index(:balance, [:user_id, :identifier])
  end

  def down do
    alter table(:balance) do
      add :genesis, :boolean, default: false, null: false
    end

    flush()

    migrate_down()

    alter table(:balance) do
      remove :name
      remove :identifier
    end
  end

  defp migrate_up(is_genesis) do
    query = from(b in "balance",
                 select: [b.id, b.genesis],
                 where: b.genesis == ^is_genesis,
                 lock: "FOR UPDATE")

    for [id, _genesis] <- Repo.all(query) do
      new_name = if is_genesis, do: "genesis", else: "primary"

      query = from(b in "balance",
                   where: b.id == ^id,
                   update: [set: [name: ^new_name, identifier: ^new_name]])

      Repo.update_all(query, [])
    end
  end

  defp migrate_down do
    query = from(b in "balance",
                 select: [b.id, b.name],
                 where: b.name == "genesis",
                 lock: "FOR UPDATE")

    for [id, _name] <- Repo.all(query) do
      query =
        from(b in "balance",
             where: b.id == ^id,
             update: [set: [genesis: true]])

      Repo.update_all(query, [])
    end
  end
end
