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

defmodule EWallet.TransactionRequestPolicy do
  @moduledoc """
  The authorization policy for accounts.
  """
  @behaviour Bodyguard.Policy
  alias EWallet.{WalletPolicy, AccountPolicy}
  alias EWalletDB.{Wallet, Account}

  def authorize(:all, _admin_user_or_key, nil), do: true

  def authorize(:all, params, %Account{} = account) do
    AccountPolicy.authorize(:get, params, account.id)
  end

  def authorize(:get, _params, _request) do
    true
  end

  def authorize(:join, %{admin_user: _} = params, request) do
    authorize(:get, params, request)
  end

  def authorize(:join, %{key: _} = params, request) do
    authorize(:get, params, request)
  end

  def authorize(:join, %{end_user: _} = params, request) do
    WalletPolicy.authorize(:join, params, request.wallet)
  end

  # Check with the passed attributes if the current accessor can
  # create a request for the account
  def authorize(:create, params, %Wallet{} = wallet) do
    WalletPolicy.authorize(:admin, params, wallet)
  end

  def authorize(_, _, _), do: false
end
