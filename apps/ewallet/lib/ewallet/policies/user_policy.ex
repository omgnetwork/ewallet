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

defmodule EWallet.UserPolicy do
  @moduledoc """
  The authorization policy for users.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.PolicyHelper

  def authorize(:all, attrs, nil) do
    PolicyHelper.can?(attrs, action: :read, type: :end_users)
  end

  def authorize(:get, attrs, end_user) do
    PolicyHelper.can?(attrs, action: :read, target: end_user)
  end

  def authorize(:join, attrs, end_user) do
    PolicyHelper.can?(attrs, action: :listen, target: end_user)
  end

  def authorize(:create, attrs, end_user) do
    PolicyHelper.can?(attrs, action: :create, target: end_user)
  end

  def authorize(:verify_email, attrs, end_user) do
    PolicyHelper.can?(attrs, action: :verify_email, target: end_user)
  end

  def authorize(:enable_or_disable, attrs, end_user) do
    PolicyHelper.can?(attrs, action: :enable_or_disable, target: end_user)
  end

  def authorize(_, _, _), do: false
end
