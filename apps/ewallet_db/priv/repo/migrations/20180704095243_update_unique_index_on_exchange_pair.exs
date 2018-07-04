defmodule EWalletDB.Repo.Migrations.UpdateUniqueIndexOnExchangePair do
  use Ecto.Migration

  def up do
    execute ~s"DROP INDEX exchange_pair_from_token_uuid_to_token_uuid_deleted_at_index"

    execute ~s"CREATE UNIQUE INDEX exchange_pair_from_token_uuid_to_token_uuid_deleted_at_not_null
               ON exchange_pair (from_token_uuid, to_token_uuid, deleted_at)
               WHERE deleted_at IS NOT NULL"

    execute ~s"CREATE UNIQUE INDEX exchange_pair_from_token_uuid_to_token_uuid_deleted_at_null
               ON exchange_pair (from_token_uuid, to_token_uuid)
               WHERE deleted_at IS NULL"
  end

  def down do
    execute ~s"DROP INDEX exchange_pair_from_token_uuid_to_token_uuid_deleted_at_not_null"

    execute ~s"DROP INDEX exchange_pair_from_token_uuid_to_token_uuid_deleted_at_null"

    execute ~s"CREATE UNIQUE INDEX exchange_pair_from_token_uuid_to_token_uuid_deleted_at_index
               ON exchange_pair (from_token_uuid, to_token_uuid, deleted_at)"
  end
end
