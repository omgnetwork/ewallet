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

defmodule EWallet.AccountPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.PolicyHelper
  alias EWalletDB.Account

  # Allowed for any role, filtering is
  # handled at the controller level to only return
  # allowed records. Should this be handled here?
  def authorize(:all, _params, nil), do: true

  # access key have admin rights so we only check that the target is
  # a descendant of the access key's account.
  def authorize(_action, %{account: account}, account_id) do
    Account.descendant?(account, account_id)
  end

  def authorize(action, %{key: key}, account_id) do
    authorize(action, %{account: key.account}, account_id)
  end

  def authorize(:get, %{admin_user: user}, account_id) do
    PolicyHelper.viewer_authorize(user, account_id)
  end

  def authorize(:join, param, account_id), do: authorize(:get, param, account_id)

  # create/update/delete/join, or anything else.
  def authorize(_, %{admin_user: user}, account_id) do
    PolicyHelper.admin_authorize(user, account_id)
  end

  def authorize(_, _, _), do: false
end
