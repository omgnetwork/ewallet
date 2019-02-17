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

defmodule EWallet.ConfigurationPolicy do
  @moduledoc """
  The authorization policy for configuration.
  """
  @behaviour Bodyguard.Policy
  alias EWalletDB.{Account, User}

  def authorize(:get, _user_or_key, _category_id), do: true

  def authorize(_, %{key: key}, _category_id) do
    Account.get_master_account().uuid == key.account.uuid
  end

  def authorize(_, %{admin_user: user}, _category_id) do
    User.master_admin?(user.id)
  end

  def authorize(_, _, _), do: false
end
