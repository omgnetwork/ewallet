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

defmodule EWallet.AccountMembershipPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.Permissions

  def authorize(:all, attrs, account_id) do
    Permissions.can?(attrs, %{action: :all, type: :memberships, target: account_id})
  end

  def authorize(:get, attrs, account_id) do
    Permissions.can?(attrs, %{action: :get, type: :memberships, target: account_id})
  end

  def authorize(:create, attrs, account_id) do
    Permissions.can?(attrs, %{action: :create, type: :memberships, target: account_id})
  end

  def authorize(:update, attrs, account_id) do
    Permissions.can?(attrs, %{action: :update, type: :memberships, target: account_id})
  end

  def authorize(:delete, attrs, account_id) do
    Permissions.can?(attrs, %{action: :delete, type: :memberships, target: account_id})
  end

  def authorize(_, _, _), do: false
end
