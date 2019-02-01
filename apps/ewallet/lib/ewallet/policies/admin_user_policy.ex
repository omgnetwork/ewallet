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

defmodule EWallet.AdminUserPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.PolicyHelper

  def authorize(:all, attrs, nil) do
    PolicyHelper.can?(attrs, action: :all, type: :admin_users)
  end

  def authorize(:get, attrs, admin_user) do
    PolicyHelper.can?(attrs, action: :read, target: admin_user)
  end

  def authorize(:join, attrs, admin_user) do
    PolicyHelper.can?(attrs, action: :listen, target: admin_user)
  end

  def authorize(:create, attrs, admin_user) do
    PolicyHelper.can?(attrs, action: :create, target: admin_user)
  end

  def authorize(:update, attrs, admin_user) do
    PolicyHelper.can?(attrs, action: :update, target: admin_user)
  end

  def authorize(:enable_or_disable, attrs, admin_user) do
    PolicyHelper.can?(attrs, action: :enable_or_disable, target: admin_user)
  end

  def authorize(_, _, _), do: false
end
