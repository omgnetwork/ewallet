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

# credo:disable-for-this-file
defmodule EWalletAPI.V1.WalletChannel do
  @moduledoc """
  Represents the address channel.
  """
  use Phoenix.Channel, async: false
  alias EWalletDB.{Wallet}
  alias EWallet.WalletPolicy

  def join("address:" <> address, _params, %{assigns: %{auth: auth}} = socket) do
    with %Wallet{} = wallet <- Wallet.get(address),
         :ok <- Bodyguard.permit(WalletPolicy, :join, auth, wallet) do
      {:ok, socket}
    else
      _ -> {:error, :forbidden_channel}
    end
  end

  def join(_, _, _), do: {:error, :invalid_parameter}
end
