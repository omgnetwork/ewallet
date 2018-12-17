defmodule EWalletConfig.Encrypted.Map do
  @moduledoc false

  use Cloak.Fields.Map, vault: EWalletConfig.Vault
end
