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

defmodule EWallet.ActivityLogPolicy do
  @moduledoc """
  The authorization policy for activity logs.
  """
  @behaviour Bodyguard.Policy
  alias EWalletDB.{Account, User}

  # Only keys belonging to master account can view all activity logs
  def authorize(:all, %{key: key}, _activity_log_id) do
    Account.get_master_account().uuid == key.account.uuid
  end

  # Only users with an admin role on master account can view all activity logs
  def authorize(:all, %{admin_user: user}, _activity_log_id) do
    User.master_admin?(user.id)
  end

  def authorize(_, _, _), do: false
end
