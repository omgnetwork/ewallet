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

defmodule EWalletDB.Repo.Migrations.UpdatePredictableMintedTokenId do
  use Ecto.Migration
  import Ecto.Query
  alias Ecto.UUID
  alias EWalletDB.Repo
  alias ExULID.ULID

  @table "minted_token"
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
    query = from(t in @table,
                 select: [t.id, t.uuid, t.symbol, t.metadata],
                 lock: "FOR UPDATE")

    for [id, uuid, symbol, metadata] <- Repo.all(query) do
      new_id = compute_id(@prefix, symbol, @ulid_timestamp, uuid)

      # Let's also keep the original ID in metadata otherwise it'll be irrecoverable for rollback.
      metadata = Map.put(metadata, :migration_original_id, id)

      query = from(t in @table,
                   where: t.uuid == ^uuid,
                   update: [set: [id: ^new_id, metadata: ^metadata]])

      Repo.update_all(query, [])
    end
  end

  # We'll prepare the new ID using <prefix><symbol>_<ulid_timestamp><uuid_first_16_chars> format.
  # Since uuid characters are a subset of Crockford's base32, we can use parts of the existing uuid
  # as the randomness of the new sync'ed id. They don't represent the same decoded data but we are
  # not concerned about that, we just need a consistent ID value.
  defp compute_id(prefix, symbol, ulid_timestamp, uuid) do
    # UUID's format is "756412b1-4a79-4963-9017-4eb49845c740" so we'll need the first 3 parts
    {:ok, uuid} = UUID.cast(uuid)
    [first, second, third, _discard] = String.split(uuid, "-", parts: 4)

    prefix <> symbol <> "_" <> ulid_timestamp <> first <> second <> third
  end

  # Rollback
  def down do
    query = from(t in @table,
                 select: [t.uuid, t.metadata, t.symbol, t.inserted_at],
                 lock: "FOR UPDATE")

    for [uuid, metadata, symbol, inserted_at] <- Repo.all(query) do
      {id, metadata} = revert(metadata, @prefix, symbol, inserted_at)

      query = from(t in @table,
                   where: t.uuid == ^uuid,
                   update: [set: [id: ^id, metadata: ^metadata]])

      Repo.update_all(query, [])
    end
  end

  # Revert back the ID and metadata if possible, otherwise re-generate the ID.
  defp revert(%{"migration_original_id" => original_id} = metadata, _prefix, _symbol, _inserted_at) do
    {original_id, Map.delete(metadata, "migration_original_id")}
  end
  defp revert(metadata, prefix, symbol, inserted_at) do
    with {date, {hours, minutes, seconds, microseconds}} <- inserted_at,
         erlang_time <- {date, {hours, minutes, seconds}},
         {:ok, naive} <- NaiveDateTime.from_erl(erlang_time, {microseconds, 6}),
         {:ok, datetime} <- DateTime.from_naive(naive, "Etc/UTC"),
         unix_time <- DateTime.to_unix(datetime, :millisecond),
         ulid <- prefix <> symbol <> "_" <> ULID.generate(unix_time)
    do
      {ulid, metadata}
    end
  end
end
