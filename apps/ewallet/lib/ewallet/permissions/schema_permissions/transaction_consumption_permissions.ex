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

defmodule EWallet.SchemaPermissions.TransactionConsumptionPermissions do
  @moduledoc """
  A policy helper containing the actual authorization.
  """
  alias EWalletDB.TransactionConsumption

  # account transaction consumptions
  def get_target_type(%TransactionConsumption{user_uuid: nil}) do
    :account_transaction_consumptions
  end

  # account transaction consumptions
  def get_target_type(%TransactionConsumption{user_uuid: user_uuid}) when not is_nil(user_uuid) do
    :end_user_transaction_consumptions
  end

  # account transaction consumptions
  def get_target_accounts(%TransactionConsumption{user_uuid: nil} = target) do
    [target.account]
  end

  # account transaction consumptions
  def get_target_accounts(%TransactionConsumption{user_uuid: user_uuid} = target)
      when not is_nil(user_uuid) do
    get_target_accounts(target.user)
  end
end
