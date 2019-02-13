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

# credo:disable-for-this-file
defmodule AdminAPI.V1.AccountChannel do
  @moduledoc """
  Represents the account channel.
  """
  use Phoenix.Channel, async: false
  alias EWallet.AccountPolicy
  alias EWalletDB.Account

  def join("account:" <> account_id, _params, %{assigns: %{auth: auth}} = socket) do
    with %Account{} = account <- Account.get_by(id: account_id) || {:error, :unauthorized},
         {:ok, _} <- AccountPolicy.authorize(:listen, auth, account) do
      {:ok, socket}
    else
      _ -> {:error, :forbidden_channel}
    end
  end

  def join(_, _, _), do: {:error, :invalid_parameter}
end
