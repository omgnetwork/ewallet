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

defmodule EWalletDB.Repo.Seeds.BlockchainHDWallet do
  alias EWalletDB.BlockchainHDWallet
  alias Keychain.Wallet
  alias EWalletDB.Seeder

  def seed do
    [
      run_banner: "Seeding HD root wallet:",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    case BlockchainHDWallet.get_primary() do
      nil ->
        insert(writer)
      hd_wallet ->
        writer.error("""
          Blockchain HD Wallet already exists: #{hd_wallet.uuid}.
        """)
    end
  end

  defp insert(writer) do
    adapter = Application.get_env(:ewallet_db, :blockchain_adapter)
    identifier = adapter.helper().identifier()

    {:ok, keychain_hd_wallet_uuid} = Wallet.generate_hd()

    attrs = %{
      keychain_uuid: keychain_hd_wallet_uuid,
      blockchain_identifier: identifier,
      originator: %Seeder{}
    }
    case BlockchainHDWallet.insert(attrs) do
      {:ok, wallet} ->
        writer.success("""
          UUID                : #{wallet.uuid}
          Keychain UUID       : #{wallet.keychain_uuid}
        """)
      {:error, changeset} ->
        writer.error("  HD Wallet #{keychain_hd_wallet_uuid} could not be inserted.")
        writer.print_errors(changeset)
      _ ->
        writer.error("  HD Wallet #{keychain_hd_wallet_uuid} could not be inserted.")
        writer.error("  Unknown error.")
    end
  end
end
