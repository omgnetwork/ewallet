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

defmodule LocalLedgerDB.Repo.Migrations.UpdatePredictableMintedTokenId do
  use Ecto.Migration
  import Ecto.Query
  alias Ecto.UUID
  alias ExULID.ULID
  alias LocalLedgerDB.Repo

  @prefix "tok_"
  @ulid_timestamp "01ccmny8yn"

  # Migrate up
  #
  # Because minted token's IDs need to be sync'ed between `ewallet_db` and `local_ledger_db`,
  # we need some way for the two databases to update to new ID format with consistent ID,
  # at the same time not coupling the two database's migrations together.
  #
  # This is achieved by knowing that there are two moving factors in the new ID format,
  # the ULID's timestamp (first 10 characters) and randomness (16 following characters).
  # We can construct a predictable minted token ID by fixing the timestamp part to a specific value,
  # and use the leading part of existing uuid (the shared value between the two database)
  # for the 16-character randomness.
  def up do
    ##################
    # Add new fields #
    ##################
    alter table(:minted_token) do
      add :new_id, :string, null: true
    end

    create index(:minted_token, :new_id, unique: true)

    alter table(:transaction) do
      add :new_minted_token_id, references(:minted_token, type: :string, column: :new_id),
                                null: true
    end

    flush()

    #######################
    # Populate new fields #
    #######################
    query = from(t in "minted_token",
                 select: [t.id, t.uuid, t.metadata],
                 lock: "FOR UPDATE")

    for [id, uuid, metadata] <- Repo.all(query) do
      # The id's format is "OMG:756412b1-4a79-4963-9017-4eb49845c740", split to get symbol and uuid.
      [symbol, ewallet_uuid] = String.split(id, ":")
      new_id = compute_id(@prefix, symbol, @ulid_timestamp, ewallet_uuid)

      # Let's also keep the original ID in metadata otherwise it'll be irrecoverable for rollback.
      metadata = Map.put(metadata, :migration_original_id, id)

      query = from(t in "minted_token",
                   where: t.uuid == ^uuid,
                   update: [set: [new_id: ^new_id, metadata: ^metadata]])

      Repo.update_all(query, [])

      query = from(t in "transaction",
                   where: t.minted_token_id == ^id,
                   update: [set: [new_minted_token_id: ^new_id]])

      Repo.update_all(query, [])

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

    # Now that the `new_minted_token_id` column is populated, disallow null values.
    # Then, remove the old `minted_token_id` column and replace it with the new one
    alter table(:transaction) do
      modify :new_minted_token_id, :string, null: false
      remove(:minted_token_id)
    end
    rename table(:transaction), :new_minted_token_id, to: :minted_token_id

    # Now that the `new_id` column is populated, disallow null values.
    # Then, remove the old `id` column and replace it with the new one
    alter table(:minted_token) do
      modify :new_id, :string, null: false
      remove(:id)
    end
    rename table(:minted_token), :new_id, to: :id
    flush()

    ##################
    # Rename indexes #
    ##################

    # Indexes and constraints don't get renamed when fields are renamed,
    # so we manually rename them for consistency.
    execute """
      ALTER INDEX minted_token_new_id_index
      RENAME TO minted_token_id_index
      """

    execute """
      ALTER TABLE transaction
      RENAME CONSTRAINT transaction_new_minted_token_id_fkey
      TO transaction_minted_token_id_fkey
      """
  end

  # We'll prepare the new ID using <prefix><symbol>_<ulid_timestamp><uuid_first_16_chars> format.
  # Since uuid characters are a subset of Crockford's base32, we can use parts of the existing uuid
  # as the randomness of the new sync'ed id. They don't represent the same decoded data but we are
  # not concerned about that, we just need a consistent ID value.
  defp compute_id(prefix, symbol, ulid_timestamp, uuid) do
    # UUID's format is "756412b1-4a79-4963-9017-4eb49845c740" so we'll need the first 3 parts
    {:ok, uuid} = UUID.cast(uuid)
    [first, second, third, _remaining] = String.split(uuid, "-", parts: 4)

    prefix <> symbol <> "_" <> ulid_timestamp <> first <> second <> third
  end

  # Rollback
  def down do
    ##################
    # Add new fields #
    ##################
    alter table(:minted_token) do
      add :old_id, :string, null: true
    end

    create index(:minted_token, :old_id, unique: true)

    alter table(:transaction) do
      add :old_minted_token_id, references(:minted_token, type: :string, column: :old_id),
                                null: true
    end

    flush()

    #######################
    # Populate new fields #
    #######################
    query = from(t in "minted_token",
                 select: [t.id, t.uuid, t.metadata, t.inserted_at],
                 lock: "FOR UPDATE")

    for [id, uuid, metadata, inserted_at] <- Repo.all(query) do
      {old_id, metadata} = revert(metadata, @prefix, id, inserted_at)

      query = from(t in "minted_token",
                   where: t.uuid == ^uuid,
                   update: [set: [old_id: ^old_id, metadata: ^metadata]])

      Repo.update_all(query, [])

      query = from(t in "transaction",
                   where: t.minted_token_id == ^id,
                   update: [set: [old_minted_token_id: ^old_id]])

      Repo.update_all(query, [])

      query = from(t in "cached_balance",
                   where: fragment("amounts \\? ?", ^id),
                   update: [set: [amounts: fragment("amounts - ? || jsonb_build_object(?, amounts->?)",
                                                    type(^id, :string),
                                                    type(^old_id, :string),
                                                    type(^id, :string))]])

      Repo.update_all(query, [])
    end

    #################################
    # Swap old fields with new ones #
    #################################

    # Now that the `old_minted_token_id` column is populated, disallow null values.
    # Remove the old `minted_token_id` column and replace it with the new one
    alter table(:transaction) do
      modify :old_minted_token_id, :string, null: false
      remove(:minted_token_id)
    end
    rename table(:transaction), :old_minted_token_id, to: :minted_token_id
    flush()

    # Now that the `old_id` column is populated, disallow null values.
    # Then, remove the old `id` column and replace it with the new one
    alter table(:minted_token) do
      modify :old_id, :string, null: false
      remove(:id)
    end
    rename table(:minted_token), :old_id, to: :id
    flush()

    ##################
    # Rename indexes #
    ##################

    # Indexes and constraints don't get renamed when fields are renamed,
    # so we manually rename them for consistency.
    execute """
      ALTER INDEX minted_token_old_id_index
      RENAME TO minted_token_id_index
      """

    execute """
      ALTER TABLE transaction
      RENAME CONSTRAINT transaction_old_minted_token_id_fkey
      TO transaction_minted_token_id_fkey
      """
  end

  # Revert back the ID and metadata if possible, otherwise re-generate the ID.
  defp revert(%{"migration_original_id" => original_id} = metadata, _prefix, _id, _inserted_at) do
    {original_id, Map.delete(metadata, "migration_original_id")}
  end
  defp revert(metadata, prefix, id, inserted_at) do
    with [_prefix, symbol, _remaining_id] <- String.split(id),
         {date, {hours, minutes, seconds, microseconds}} <- inserted_at,
         erlang_time <- {date, {hours, minutes, seconds}},
         {:ok, naive} <- NaiveDateTime.from_erl(erlang_time, {microseconds, 6}),
         {:ok, datetime} <- DateTime.from_naive(naive, "Etc/UTC"),
         unix_time <- DateTime.to_unix(datetime, :millisecond),
         ulid <- prefix <> symbol <> "_" <> ULID.generate(unix_time)
    do
      {ulid, metadata}
    else
      _ ->
        {id, metadata}
    end
  end
end
