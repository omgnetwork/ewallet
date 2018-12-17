defmodule EWalletDB.Encrypted.Map do
  @moduledoc false

  use Cloak.Fields.Map, vault: EWalletDB.Vault
end
