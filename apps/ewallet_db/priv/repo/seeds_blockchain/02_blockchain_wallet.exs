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

defmodule EWalletDB.Repo.Seeds.BlockchainWallet do
  alias EWalletDB.{BlockchainWallet, Seeder}
  alias Keychain.Wallet
  alias EWalletConfig.Config

  def seed do
    [
      run_banner: "Seeding primary hot wallet:",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    identifier = Application.get_env(:ewallet_db, :rootchain_identifier)

    case BlockchainWallet.get_primary_hot_wallet(identifier) do
      nil -> insert_wallet(writer, identifier)
      wallet ->
        writer.warn("""
          Skipping hot wallet generation, #{wallet.name} is already in the database.

          Name                : #{wallet.name}
          Address             : #{wallet.address}
          Public key          : #{wallet.public_key}
          Type                : #{wallet.type}
        """)
    end
  end

  defp insert_wallet(writer, identifier) do
    {:ok, {address, public_key}} = Wallet.generate()

    attrs = %{
      address: address,
      public_key: public_key,
      name: "Hot Wallet",
      type: BlockchainWallet.type_hot(),
      blockchain_identifier: identifier,
      originator: %Seeder{}
    }

    case BlockchainWallet.insert_hot(attrs) do
      {:ok, wallet} ->
        {:ok, [primary_hot_wallet: {:ok, _}]} =
          Config.update(%{
            primary_hot_wallet: wallet.address,
            originator: %Seeder{}
          })

        writer.success("""
          Name                : #{wallet.name}
          Address             : #{wallet.address}
          Public key          : #{wallet.public_key}
          Type                : #{wallet.type}
        """)

      {:error, changeset} ->
        writer.error("  Wallet #{address} could not be inserted.")
        writer.print_errors(changeset)

      _ ->
        writer.error("  Wallet #{address} could not be inserted.")
        writer.error("  Unknown error.")
    end
  end
end
