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
  alias EWallet.PolicyHelper
  alias EWallet.{Bouncer, Bouncer.Permission}
  alias EWalletDB.Membership

  @spec authorize(any(), any(), any()) ::
          {:error, EWallet.Bouncer.Permission.t()} | {:ok, EWallet.Bouncer.Permission.t()}
  def authorize(:create, actor, %Membership{account: account, account_uuid: account_uuid}) do
    Bouncer.bounce(actor, %Permission{
      action: :create,
      target: %Membership{account: account, account_uuid: account_uuid}
    })
  end

  def authorize(action, actor, target) do
    PolicyHelper.authorize(action, actor, :memberships, Membership, target)
  end
end
