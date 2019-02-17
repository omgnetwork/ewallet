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

defmodule EWallet.APIKeyPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWalletDB.{Account, User}

  # API keys can only be managed from the master account,
  # but can be seen and used by any account.

  # Allowed for any role, filtering is
  # handled at the controller level to only return
  # allowed records. Should this be handled here?
  def authorize(:all, _params, nil), do: true

  # access key have admin rights so we only check that the target is
  # a descendant of the access key's account.
  def authorize(_action, %{key: key}, _api_key_id) do
    Account.get_master_account().uuid == key.account.uuid
  end

  # Any other action requires the user to have an admin membership
  # on the master account
  def authorize(_action, %{admin_user: user}, _api_key_id) do
    User.master_admin?(user.id)
  end

  def authorize(_, _, _), do: false
end
