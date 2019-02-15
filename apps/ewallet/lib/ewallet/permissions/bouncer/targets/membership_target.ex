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

defmodule EWallet.Bouncer.MembershipTarget do
  @moduledoc """
  A policy helper containing the helper methods for the membership permissions checks.
  """
  @behaviour EWallet.Bouncer.TargetBehaviour
  alias EWalletDB.{Membership, Helpers.Preloader}

  def get_owner_uuids(%Membership{account_uuid: account_uuid, user_uuid: user_uuid}) when not is_nil(user_uuid) do
    [account_uuid, user_uuid]
  end

  def get_owner_uuids(%Membership{account_uuid: account_uuid, key_uuid: key_uuid}) when not is_nil(key_uuid)  do
    [account_uuid, key_uuid]
  end

  def get_target_type(%Membership{}) do
    :memberships
  end

  def get_target_accounts(%Membership{} = membership) do
    [Preloader.preload(membership, [:account]).account]
  end
end
