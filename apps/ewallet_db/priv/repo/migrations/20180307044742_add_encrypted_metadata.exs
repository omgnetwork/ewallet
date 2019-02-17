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

# credo:disable-for-this-file
defmodule EWalletDB.Repo.Migrations.AddEncryptedMetadata do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  @tables [:balance, :minted_token, :transfer, :user]

  def up do
    Enum.each(@tables, fn table_name ->
      alter table(table_name) do
        add :encrypted_metadata, :binary
      end

      flush()
      table_name |> Atom.to_string() |> migrate_to_encrypted_metadata()

      alter table(table_name) do
        remove :metadata
        add :metadata, :map, null: false, default: "{}"
      end

      create index(table_name, [:metadata], using: "gin")
    end)
  end

  def down do
    Enum.each(@tables, fn table_name ->
      drop index(table_name, [:metadata])

      alter table(table_name) do
        remove :metadata
        add :metadata, :binary
      end

      flush()
      table_name |> Atom.to_string() |> migrate_to_metadata()

      alter table(table_name) do
        remove :encrypted_metadata
      end
    end)
  end

  defp migrate_to_encrypted_metadata(table_name) do
    query = from(b in table_name,
                 select: [b.id, b.metadata],
                 lock: "FOR UPDATE")

    for [id, metadata] <- Repo.all(query) do
      query = from(b in table_name,
                  where: b.id == ^id,
                  update: [set: [encrypted_metadata: ^metadata]])
      Repo.update_all(query, [])
    end
  end

  defp migrate_to_metadata(table_name) do
    query = from(b in table_name,
                 select: [b.id, b.encrypted_metadata],
                 lock: "FOR UPDATE")

    for [id, encrypted_metadata] <- Repo.all(query) do
      query = from(b in table_name,
                  where: b.id == ^id,
                  update: [set: [metadata: ^encrypted_metadata]])
      Repo.update_all(query, [])
    end
  end
end
