defmodule Keychain.Repo.Migrations.AlterIdUuidInKey do
  use Ecto.Migration

  def up do
    # Change primary key from `wallet_id` to `uuid`
    execute "ALTER TABLE keychain DROP CONSTRAINT keychain_pkey"
    execute "ALTER TABLE keychain ADD PRIMARY KEY (uuid)"

    # Drop the `uuid` index since it's now the primary key
    execute "DROP INDEX keychain_uuid_index"

    # Rename `wallet_id` to `wallet_address` for clarity
    rename table("keychain"), :wallet_id, to: :wallet_address

    # Add unique index to `wallet_address` since it no longer has the primary key constraint
    create unique_index("keychain", [:wallet_address])
  end

  def down do
    # Rename `wallet_address` back to `wallet_id`
    rename table("keychain"), :wallet_address, to: :wallet_id

    # Change primary key from `uuid` back to `wallet_id`
    execute "ALTER TABLE keychain DROP CONSTRAINT keychain_pkey"
    execute "ALTER TABLE keychain ADD PRIMARY KEY (wallet_id)"

    # Drop the `wallet_id` index since it's now the primary key. We still refer to
    # the index with `wallet_address` because the column rename does not change the
    # constraint name.
    execute "DROP INDEX keychain_wallet_address_index"

    # Add index to `uuid` since it no longer has the primary key constraint.
    # We use index and not unique index here because that's what it was before this migration.
    create index("keychain", [:uuid])
  end
end
