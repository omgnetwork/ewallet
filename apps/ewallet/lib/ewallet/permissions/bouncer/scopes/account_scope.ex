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

defmodule EWallet.Bouncer.AccountScope do
  @moduledoc """

  """
  @behaviour EWallet.Bouncer.ScopeBehaviour

  @spec build_query_all(EWallet.Permission.t()) :: any()
  def build_query_all(%Permission{global_permission: :global}), do: Account

  def build_query_all(%Permission{global_permission: :accounts} = permission) do
    PermissionsHelper.get_query_actor_records(permission)
  end

  def build_query_all(%Permission{account_permission: :global}), do: Account

  def build_query_all(%Permission{account_permission: :accounts} = permission) do
    PermissionsHelper.get_query_actor_records(permission)
  end

end
