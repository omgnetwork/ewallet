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

defmodule EWalletDB.Repo.Seeds.ExchangePairSeed do
  alias EWallet.Web.Preloader
  alias EWalletDB.{ExchangePair, Token}
  alias EWalletDB.Seeder

  @pairs [
    %{from_token_symbol: "ETH", to_token_symbol: "OMG", rate: 400},

    %{from_token_symbol: "OEM", to_token_symbol: "OMG", rate: 0.001},

    %{from_token_symbol: "OMG", to_token_symbol: "OEM", rate: 1_000},
    %{from_token_symbol: "OMG", to_token_symbol: "ETH", rate: 0.0025}
  ]

  def seed do
    [
      run_banner: "Seeding sample exchange pairs:",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    Enum.each @pairs, fn args ->
      run_with(writer, args)
    end
  end

  def run_with(writer, args) do
    from_token = Token.get_by(symbol: args.from_token_symbol)
    to_token = Token.get_by(symbol: args.to_token_symbol)

    case ExchangePair.get_by([from_token_uuid: from_token.uuid, to_token_uuid: to_token.uuid]) do
      nil ->
        {:ok, pair} =
          ExchangePair.insert(%{
            from_token_uuid: from_token.uuid,
            to_token_uuid: to_token.uuid,
            rate: args.rate,
            originator: %Seeder{}
          })

        {:ok, pair} = Preloader.preload_one(pair, [:from_token, :to_token])

        writer.success("""
          Exchange Pair ID : #{pair.id}
          From Token ID    : #{pair.from_token.id}
          To Token ID      : #{pair.to_token.id}
          Rate             : #{pair.rate}
        """)

      %ExchangePair{} = pair ->
        {:ok, pair} = Preloader.preload_one(pair, [:from_token, :to_token])

        writer.warn("""
          Exchange Pair ID : #{pair.id}
          From Token ID    : #{pair.from_token.id}
          To Token ID      : #{pair.to_token.id}
          Rate             : #{pair.rate}
        """)
    end
  end
end
