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

defmodule EWalletDB.Repo.Seeds.BlockchainWalletRepresentations do
  alias EWalletDB.Wallet
  alias Keychain.Wallet
  alias EWalletDB.{Seeder, BlockchainHDWallet}

  def seed do
    [
      run_banner: "Seeding HD root wallet:",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    # TODO: add blockchain identifier
    case BlockchainHDWallet.get_primary() do
      nil ->
        insert(writer)
      hd_wallet ->
        writer.warn("""
          Blockchain HD Wallet already exists: #{hd_wallet.uuid}.
        """)
    end
  end

  defp insert(writer) do
    {:ok, keychain_hd_wallet} = Wallet.generate_hd()

    attrs = %{
      keychain_id: keychain_hd_wallet.wallet_id,
      originator: %Seeder{}
    }
    case BlockchainHDWallet.insert(attrs) do
      {:ok, wallet} ->
        writer.success("""
          UUID              : #{wallet.uuid}
          Keychain ID       : #{wallet.keychain_id}
        """)
      {:error, changeset} ->
        writer.error("  HD Wallet #{keychain_hd_wallet.uuid} could not be inserted.")
        writer.print_errors(changeset)
      _ ->
        writer.error("  HD Wallet #{keychain_hd_wallet.uuid} could not be inserted.")
        writer.error("  Unknown error.")
    end
  end
end
