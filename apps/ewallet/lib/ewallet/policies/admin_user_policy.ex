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

defmodule EWallet.AdminUserPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.PolicyHelper
  alias EWalletDB.{Account, Membership, User}

  # Allowed for any role, filtering is
  # handled at the controller level to only return
  # allowed records. Should this be handled here?
  def authorize(:all, _params, nil), do: true

  # access key have admin rights so we only check that the target is
  # a descendant of the access key's account.
  def authorize(_action, %{key: key}, user) do
    account_uuids = membership_account_uuids(user)
    Account.descendant?(key.account, account_uuids)
  end

  # compare current user descendant accounts
  # with passed user ancestors accounts to find match

  def authorize(:get, %{admin_user: admin_user}, user) do
    account_uuids = membership_account_uuids(user)
    PolicyHelper.viewer_authorize(admin_user, account_uuids)
  end

  def authorize(:enable_or_disable, %{admin_user: %{uuid: uuid}}, %User{uuid: uuid}) do
    false
  end

  # create/update/delete, or anything else.
  def authorize(_action, %{admin_user: admin_user}, user) do
    account_uuids = membership_account_uuids(user)
    PolicyHelper.admin_authorize(admin_user, account_uuids)
  end

  def authorize(_, _, _), do: false

  defp membership_account_uuids(user) do
    user
    |> Membership.all_by_user()
    |> Enum.map(fn membership -> membership.account_uuid end)
  end
end
