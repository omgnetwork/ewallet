defmodule LocalLedgerDB.Encrypted.Map do
  @moduledoc false

  use Cloak.Fields.Map, vault: LocalLedgerDB.Vault
end
