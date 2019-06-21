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

defmodule EWallet.Web.BlockchainBalanceLoader do
  @moduledoc """
  Module responsible for adding balances to wallets.
  """
  alias EWallet.BlockchainBalanceFetcher

  def balances_for_address(wallet, tokens) do
    BlockchainBalanceFetcher.all(wallet, tokens)
  end

  def balances_with_wallet(wallet, tokens) do
    case BlockchainBalanceFetcher.all(wallet, tokens) do
      {:ok, data} ->
        {:ok, add_balances_to_wallet(data, wallet)}

      err ->
        err
    end
  end

  defp add_balances_to_wallet(balances, wallet) do
    Map.put(wallet, :balances, balances)
  end
end
