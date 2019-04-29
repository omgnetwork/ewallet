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

defmodule EWallet.Bouncer.RoleTarget do
  @moduledoc """
  A policy helper containing the actual authorization for roles.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour
  alias EWalletDB.Role

  @spec get_owner_uuids(Role.t()) :: [Ecto.UUID.t()]
  def get_owner_uuids(_), do: []

  @spec get_target_types() :: [:role]
  def get_target_types, do: [:role]

  @spec get_target_type(Role.t()) :: :role
  def get_target_type(_), do: :role

  @spec get_target_accounts(Role.t(), any()) :: [Account.t()]
  def get_target_accounts(%Role{}, _dispatch_config), do: []
end
