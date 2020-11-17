# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EthOmiseGOAdapter.Config do
  @moduledoc false

  def get_plasma_framework_address do
    Application.get_env(:eth_omisego_adapter, :omisego_plasma_framework_address)
  end

  def get_eth_vault_address do
    Application.get_env(:eth_omisego_adapter, :omisego_eth_vault_address)
  end

  def get_erc20_vault_address do
    Application.get_env(:eth_omisego_adapter, :omisego_erc20_vault_address)
  end

  def get_payment_exit_game_address do
    Application.get_env(:eth_omisego_adapter, :omisego_payment_exit_game_address)
  end

  def get_watcher_url do
    Application.get_env(:eth_omisego_adapter, :omisego_watcher_url)
  end
end
