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

defmodule EWallet.Permissions do
  @moduledoc """
  The entry point module to the permissions logic.
  """
  alias EWallet.{PermissionsHelper, GlobalPermissions, AccountPermissions}

  def can?(actor, attrs) do
    case PermissionsHelper.get_actor(actor) do
      nil ->
        false

      # can?/2 returns a tuple containing {can?, account_permissions_check_allowed?}
      actor ->
        case GlobalPermissions.can?(actor, attrs) do
          {true, _} ->
            # The actor has global access so we don't check the account permissions.
            true
          {false, true} ->
            # The actor does not have global access, but can check account permissions
            # so we check them!
            AccountPermissions.can?(actor, attrs)
          {false, false} ->
            # The actor does not have global access and is not allowed to check account permissions
            # so we skip and return false
            false
        end
    end
  end
end
