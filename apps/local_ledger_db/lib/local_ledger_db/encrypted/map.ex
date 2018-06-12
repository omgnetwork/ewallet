defmodule LocalLedgerDB.Encrypted.Map do
  use Cloak.Fields.Map, vault: LocalLedgerDB.Vault
end
