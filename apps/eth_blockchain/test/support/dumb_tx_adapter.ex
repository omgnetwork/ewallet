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

defmodule EthBlockchain.DumbTxAdapter do
  @moduledoc """
  This is a dumb adapter that can be used for tests requiring a decoding of the
  raw transaction.
  With the standard EthBlockchain.DumbAdapter, the returned tx_hash is a static value
  and is sometimes not enough for tests.
  """
  use GenServer

  alias EthBlockchain.Adapter

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link, do: GenServer.start_link(__MODULE__, :ok, [])

  def init(_opts) do
    {:ok, %{}}
  end

  def stop(pid), do: GenServer.stop(pid)

  def handle_call({:send_raw, data}, _from, reg) do
    {:reply, {:ok, data}, reg}
  end

  def handle_call(call, _from, reg) do
    {:reply, Adapter.eth_call(call, []), reg}
  end
end
