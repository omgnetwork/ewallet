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

defmodule EWalletAPI.V1.Socket do
  @moduledoc """
  This module is the entry points for websocket connections to the eWallet API. It contains the
  channels to which providers/clients can connect to listen and receive events.
  """
  use Phoenix.Socket
  alias EWalletAPI.V1.ClientAuth

  channel("account:*", EWalletAPI.V1.AccountChannel)
  channel("user:*", EWalletAPI.V1.UserChannel)
  channel("address:*", EWalletAPI.V1.AddressChannel)
  channel("transaction_request:*", EWalletAPI.V1.TransactionRequestChannel)
  channel("transaction_consumption:*", EWalletAPI.V1.TransactionConsumptionChannel)

  transport(:websocket, Phoenix.Transports.WebSocket)

  def connect(params, socket) do
    case ClientAuth.authenticate(params) do
      %{authenticated: true} = client_auth ->
        {:ok, assign(socket, :auth, client_auth)}

      _ ->
        :error
    end
  end

  def id(_socket), do: nil
end
