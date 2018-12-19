{:ok, _} = Application.ensure_all_started(:ex_machina)
{:ok, _} = Application.ensure_all_started(:bypass)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(EWalletConfig.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(LocalLedgerDB.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(EWalletDB.Repo, :manual)
