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

defmodule EWallet.Bouncer.KeyTarget do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour
  alias EWalletDB.{Account, Key, Helpers.Preloader}

  @spec get_owner_uuids(Key.t()) :: [Ecto.UUID.t()]
  def get_owner_uuids(%Key{uuid: uuid}) do
    [uuid]
  end

  @spec get_target_types() :: [:access_keys]
  def get_target_types, do: [:access_keys]

  @spec get_target_type(%Key{}) :: :access_keys
  def get_target_type(_), do: :access_keys

  @spec get_target_accounts(%Key{}, any()) :: [%Account{}]
  def get_target_accounts(%Key{} = key, _dispatch_config) do
    get_actor_accounts(key)
  end

  @spec get_target_accounts(%Key{}, any()) :: [Account.t()]
  def get_actor_accounts(%Key{} = key) do
    Preloader.preload(key, [:accounts]).accounts
  end
end
