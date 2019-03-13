# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :local_ledger_db,
  ecto_repos: [LocalLedgerDB.Repo]

config :local_ledger_db, LocalLedgerDB.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: DB.SharedConnectionPool,
  pool_size: {:system, "LOCAL_LEDGER_POOL_SIZE", 10, {String, :to_integer}},
  shared_pool_id: :local_ledger,
  migration_timestamps: [type: :naive_datetime_usec]

import_config "#{Mix.env()}.exs"
