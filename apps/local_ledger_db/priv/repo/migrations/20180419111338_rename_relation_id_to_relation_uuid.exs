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

defmodule LocalLedgerDB.Repo.Migrations.RenameRelationIdToRelationUuid do
  use Ecto.Migration

  @tables [
    minted_token: [
      friendly_id: :id
    ],
    transaction: [
      minted_token_friendly_id: :minted_token_id,
      entry_id: :entry_uuid
    ]
  ]

  def up do
    Enum.each(@tables, fn({table, maps}) ->
      Enum.each(maps, fn({old, new}) ->
        rename table(table), old, to: new
      end)
    end)

    # Indexes and constraints don't get renamed when fields are renamed.
    # So we manually rename them for consistency.
    execute """
      ALTER INDEX minted_token_friendly_id_index
      RENAME TO minted_token_id_index
      """

    execute """
      ALTER TABLE transaction
      RENAME CONSTRAINT transaction_minted_token_friendly_id_fkey
      TO transaction_minted_token_id_fkey
      """

    execute """
      ALTER TABLE transaction
      RENAME CONSTRAINT transaction_entry_id_fkey
      TO transaction_entry_uuid_fkey
      """
  end

  def down do
    Enum.each(@tables, fn({table, maps}) ->
      Enum.each(maps, fn({old, new}) ->
        rename table(table), new, to: old
      end)
    end)

    execute """
      ALTER TABLE transaction
      RENAME CONSTRAINT transaction_minted_token_id_fkey
      TO transaction_minted_token_friendly_id_fkey
      """

    execute """
      ALTER INDEX minted_token_id_index
      RENAME TO minted_token_friendly_id_index
      """

    execute """
      ALTER TABLE transaction
      RENAME CONSTRAINT transaction_entry_uuid_fkey
      TO transaction_entry_id_fkey
      """
  end
end
