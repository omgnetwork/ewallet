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

defmodule EWalletDB.Repo.Seeds.BlockchainToken do
  alias EWallet.Web.Preloader
  alias EWalletDB.{Account, Token}
  alias EWalletDB.Seeder

  def seed do
    [
      run_banner: "Seeding main blockchain tokens:",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    token = EthBlockchain.Token.get_default()
    run_with(writer, token)
  end

  defp run_with(writer, data) do
    case Token.get_by(symbol: data.symbol) do
      nil ->
        writer.warn("""
          Creating token #{data.name} (#{data.symbol}) ...
        """)
        account = Account.get_master_account()
        data = data
        |> Map.put(:account_uuid, account.uuid)
        |> Map.put(:originator, %Seeder{})
        |> Map.put(:blockchain_address, data.address)
        |> Map.put(:blockchain_status, Token.blockchain_status_confirmed())

        case Token.insert(data) do
          {:ok, token} ->
            {:ok, token} = Preloader.preload_one(token, :account)
            writer.success("""
              ID                  : #{token.id}
              Name                : #{token.name}
              Symbol              : #{token.symbol}
              Blockchain Address  : #{token.blockchain_address}
              Blockchain Status   : #{token.blockchain_status}
              Subunit to unit     : #{token.subunit_to_unit}
              Account Name        : #{token.account.name}
              Account ID          : #{token.account.id}
            """)
          {:error, changeset} ->
            writer.error("  Token #{data.symbol} could not be inserted.")
            writer.print_errors(changeset)
          _ ->
            writer.error("  Token #{data.symbol} could not be inserted.")
            writer.error("  Unknown error.")
        end
      %Token{} = token ->
        {:ok, token} = Preloader.preload_one(token, :account)
        writer.error("""
          Token #{data.name} (#{token.symbol}) already exists in the database!!!

          Info:
          ID              : #{token.id}
          Subunit to unit : #{token.subunit_to_unit}
          Account Name    : #{token.account.name}
          Account ID      : #{token.account.id}
        """)
    end
  end
end
