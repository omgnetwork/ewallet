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

defmodule EWallet.AccountPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.{Permissions, Permission}
  alias EWalletDB.Account

  def authorize(:all, attrs, nil) do
    case Permissions.can(attrs, %Permission{action: :all, type: :accounts, schema: Account}) do
      {:ok, permission} ->
        {:ok, %{permission | query: Permissions.build_all_query(permission)}}

      error ->
        error
    end
  end

  def authorize(:get, attrs, account) do
    Permissions.can(attrs, %Permission{action: :get, target: account})
  end

  def authorize(:listen, attrs, account) do
    Permissions.can(attrs, %Permission{action: :listen, target: account})
  end

  def authorize(:create, attrs, _account_attrs) do
    Permissions.can(attrs, %Permission{action: :create, target: %Account{}})
  end

  def authorize(:update, attrs, account) do
    Permissions.can(attrs, %Permission{action: :update, target: account})
  end

  def authorize(_, _, _), do: false
end
