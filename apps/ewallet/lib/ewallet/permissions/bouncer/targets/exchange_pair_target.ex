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

defmodule EWallet.Bouncer.ExchangePairTarget do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour
  alias EWalletDB.ExchangePair

  @spec get_owner_uuids(ExchangePair.t()) :: [Ecto.UUID.t()]
  def get_owner_uuids(_) do
    []
  end

  @spec get_target_types() :: [:exchange_pairs]
  def get_target_types, do: [:exchange_pairs]

  @spec get_target_type(ExchangePair.t()) :: :exchange_pairs
  def get_target_type(_), do: :exchange_pairs

  @spec get_target_accounts(ExchangePair.t(), any()) :: [Account.t()]
  def get_target_accounts(%ExchangePair{}, _dispatch_config), do: []
end
