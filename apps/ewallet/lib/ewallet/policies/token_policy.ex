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

defmodule EWallet.TokenPolicy do
  @moduledoc """
  The authorization policy for tokens.
  """
  alias EWallet.PolicyHelper
  alias EWallet.{Bouncer, Bouncer.Permission}
  alias EWalletDB.Token

  def authorize(:create, attrs, %{"account_uuid" => account_uuid}) do
    Bouncer.bounce(attrs, %Permission{action: :create, target: %Token{account_uuid: account_uuid}})
  end

  def authorize(action, attrs, target) do
    PolicyHelper.authorize(action, attrs, :tokens, Token, target)
  end
end
