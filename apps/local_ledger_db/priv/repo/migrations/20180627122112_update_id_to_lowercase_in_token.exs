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

defmodule LocalLedgerDB.Repo.Migrations.UpdateIdToLowercaseInToken do
  use Ecto.Migration
  import Ecto.Query
  alias LocalLedgerDB.Repo

  def up do
    ##################
    # Add new fields #
    ##################
    alter table(:token) do
      add :new_id, :string, null: true
    end

    create index(:token, :new_id, unique: true)

    alter table(:entry) do
      add :new_token_id, references(:token, type: :string, column: :new_id),
                                    null: true
    end

    flush()

    #######################
    # Populate new fields #
    #######################
    query = from(t in "token",
                 select: [t.uuid, t.id],
                 lock: "FOR UPDATE")

    for [uuid, id] <- Repo.all(query) do
      [prefix, symbol, ulid] = String.split(id, "_", parts: 3)
      new_id = prefix <> "_" <> symbol <> "_" <> String.downcase(ulid)

      # Update `token` table
      query = from(t in "token",
                   where: t.uuid == ^uuid,
                   update: [set: [new_id: ^new_id]])

      Repo.update_all(query, [])

      # Update `entry` table
      query = from(t in "entry",
                   where: t.token_id == ^id,
                   update: [set: [new_token_id: ^new_id]])

      Repo.update_all(query, [])

      # Update `cached_balance` table
      query = from(t in "cached_balance",
                   where: fragment("amounts \\? ?", ^id),
                   update: [set: [amounts: fragment("amounts - ? || jsonb_build_object(?, amounts->?)",
                                                    type(^id, :string),
                                                    type(^new_id, :string),
                                                    type(^id, :string))]])

      Repo.update_all(query, [])
    end

    #################################
    # Swap old fields with new ones #
    #################################

    alter table(:entry) do
      modify :new_token_id, :string, null: false
      remove(:token_id)
    end
    rename table(:entry), :new_token_id, to: :token_id

    alter table(:token) do
      modify :new_id, :string, null: false
      remove(:id)
    end
    rename table(:token), :new_id, to: :id

    flush()

    ##################
    # Rename indexes #
    ##################

    # Indexes and constraints don't get renamed when fields are renamed,
    # so we manually rename them for consistency.
    execute """
      ALTER INDEX token_new_id_index
      RENAME TO token_id_index
      """

    execute """
      ALTER TABLE entry
      RENAME CONSTRAINT entry_new_token_id_fkey
      TO entry_token_id_fkey
      """
  end

  def down do
    # Not converting the uppercase back because:
    # 1. We don't know which tokens had uppercases (tokens inserted before this migration),
    #    and which had lowercases (tokens created after this migration).
    # 2. The lowercased ID should still work.
    # 3. `up/0` can be called again without breaking.
  end
end
