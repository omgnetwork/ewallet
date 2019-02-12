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

defmodule EWallet.TransactionConsumptionPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  alias EWallet.{PolicyHelper, Permissions, Permission}
  alias EWalletDB.TransactionConsumption

  def authorize(:create, attrs, _attrs) do
    Permissions.can(attrs, %Permission{action: :create, target: %TransactionConsumption{}})
  end

  def authorize(action, attrs, target) do
    PolicyHelper.authorize(
      action,
      attrs,
      :transaction_consumptions,
      TransactionConsumption,
      target
    )
  end
end
