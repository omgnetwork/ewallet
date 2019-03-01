# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWallet.Bouncer.MintTarget do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour
  alias EWalletDB.{Mint, Helpers.Preloader}

  @spec get_owner_uuids(Mint.t()) :: [Ecto.UUID.t()]
  def get_owner_uuids(%Mint{token: token}), do: [token.account_uuid]

  @spec get_target_types() :: [:mints]
  def get_target_types, do: [:mints]

  @spec get_target_type(Mint.t()) :: :mints
  def get_target_type(_), do: :mints

  @spec get_target_accounts(Mint.t(), any()) :: [Account.t()]
  def get_target_accounts(%Mint{token: token}, _dispatch_config) do
    [Preloader.preload(token, [:account]).account]
  end
end
