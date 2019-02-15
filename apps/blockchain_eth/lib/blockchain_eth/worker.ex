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

defmodule BlockchainEth.Worker do
  @moduledoc false

  @type server :: GenServer.server()
  @typep from :: GenServer.from()
  @typep state :: nil
  @typep resp(ret) :: ret | {:error, atom()}
  @typep reply(ret) :: {:reply, resp(ret), state()}

  ## Genserver
  ##

  use GenServer
  alias ExthCrypto.ECIES.ECDH
  alias Ecto.UUID

  @doc """
  Starts BlockchainEth.Worker.
  """
  @spec start_link() :: GenServer.on_start()
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Initialize the registry.
  """
  @spec init(:ok) :: {:ok, nil}
  def init(:ok) do
    {:ok, nil}
  end

  @doc """
  Stops BlockchainEth.Worker.
  """
  @spec stop() :: :ok
  @spec stop(server()) :: :ok
  def stop(pid \\ __MODULE__) do
    GenServer.stop(pid)
  end

  ## Callbacks
  ##

  @doc """
  Handles the generate_wallet call from the cliet API generate_wallet/1.
  """
  @spec handle_call(:generate_wallet, from(), state()) :: reply({:ok, String.t(), String.t()})
  def handle_call(:generate_wallet, _from, reg) do
    {public_key, _private_key} = ECDH.new_ecdh_keypair()
    {:reply, {:ok, UUID.generate(), public_key}, reg}
  end

  ## Client API
  ##

  @doc """
  Generates a Elliptic Curve Diffie-Hellman keypair for Ethereum.

  Returns a tuple of `{:ok, wallet_id, public_key}` in case of a successful
  wallet generation otherwise returns `{:error, error_code}`.
  """
  @spec generate_wallet(server()) :: resp({:ok, atom(), String.t()})
  @spec generate_wallet() :: resp({:ok, atom(), String.t()})
  def generate_wallet(pid \\ __MODULE__) do
    GenServer.call(pid, :generate_wallet)
  end
end
