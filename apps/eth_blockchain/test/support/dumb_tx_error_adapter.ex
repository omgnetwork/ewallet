# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EthBlockchain.DumbTxErrorAdapter do
  @moduledoc """
  This is a dumb adapter that returns a geth error.
  """
  use GenServer

  alias EthBlockchain.AdapterServer

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: GenServer.start_link(__MODULE__, :ok, [])

  def init(_opts) do
    {:ok, %{}}
  end

  def stop(pid), do: GenServer.stop(pid)

  def handle_call({:send_raw, _}, _from, reg) do
    error = {:error, :geth_error, [error_message: "insufficient funds for gas * price + value"]}
    {:reply, error, reg}
  end

  def handle_call(call, _from, reg) do
    {:reply, AdapterServer.eth_call(call, []), reg}
  end
end
