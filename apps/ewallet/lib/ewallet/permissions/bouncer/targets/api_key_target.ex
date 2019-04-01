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

defmodule EWallet.Bouncer.APIKeyTarget do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour

  @spec get_owner_uuids(%EWalletDB.APIKey{}) :: [Ecto.UUID.t()]
  def get_owner_uuids(%{creator_user_uuid: uuid}), do: [uuid]

  def get_owner_uuids(%{creator_key_uuid: uuid}), do: [uuid]

  @spec get_target_types() :: [:api_keys]
  def get_target_types, do: [:api_keys]

  @spec get_target_type(%EWalletDB.APIKey{}) :: :api_keys
  def get_target_type(_), do: :api_keys

  @spec get_target_accounts(%EWalletDB.APIKey{}, any()) :: []
  def get_target_accounts(_api_key, _dispatch_config), do: []
end
