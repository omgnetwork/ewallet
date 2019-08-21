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

defmodule EthBlockchain.Adapter do
  @moduledoc false

  @typep server :: GenServer.server()
  @typep from :: GenServer.from()
  @typep state :: {atom(), map()}

  @typep adapter :: EthBlockchain.adapter()
  @typep call :: EthBlockchain.call()
  @typep mfargs :: {module(), atom(), [term()]}

  @typep resp(ret) :: ret | {:error, atom()}
  @typep reply(ret) :: {:reply, resp(ret), state()}

  ## Genserver
  ##

  use GenServer
  require Logger

  alias EthBlockchain.{
    Balance,
    Block,
    Contract,
    Childchain,
    DumbAdapter,
    ErrorHandler,
    Helper,
    Token,
    Transaction,
    TransactionListener,
    BlockchainRegistry
  }

  def helper, do: Helper
  def error_handler, do: ErrorHandler
  def dumb_adapter, do: DumbAdapter

  @doc """
  Starts EthBlockchain.Adapter.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    :ok = Logger.info("Running EthBlockchain Adapter supervisor.")

    {supervisor, opts} = Keyword.pop(opts, :supervisor)
    {adapters, opts} = Keyword.pop(opts, :adapters, [])
    {named, opts} = Keyword.pop(opts, :named, false)

    opts =
      case named do
        true ->
          Keyword.merge(opts, name: __MODULE__)

        false ->
          opts
      end

    GenServer.start_link(__MODULE__, {supervisor, adapters}, opts)
  end

  @doc """
  Initialize the registry.
  """
  @spec init({atom(), list()}) :: {:ok, state()}
  def init({supervisor, adapters}) do
    handlers =
      Enum.into(adapters, %{}, fn {adapter, mod} ->
        {adapter, normalize_adapter_mod(mod)}
      end)

    {:ok, {supervisor, handlers}}
  end

  @doc """
  Stops EthBlockchain.Adapter.
  """
  @spec stop(server()) :: :ok
  def stop(pid \\ __MODULE__) do
    :ok = Logger.info("Stopping EthBlockchain Adapter supervisor")
    GenServer.stop(pid)
  end

  ## Utilities
  ##

  @spec adapter_name(adapter()) :: atom()
  defp adapter_name({adapter, wallet_id}) do
    case wallet_id do
      nil ->
        String.to_atom("adapter-#{adapter}")

      n ->
        String.to_atom("adapter-#{adapter}-#{n}")
    end
  end

  @spec normalize_adapter_mod(module() | mfargs()) :: mfargs()
  defp normalize_adapter_mod(module) when is_atom(module) do
    {module, :start_link, []}
  end

  defp normalize_adapter_mod({module, func, args}) do
    {module, func, args}
  end

  @spec ensure_adapter_started(atom() | adapter(), state()) :: resp({:ok, server()})
  defp ensure_adapter_started(adapter, state) when is_atom(adapter) do
    ensure_adapter_started({adapter, nil}, state)
  end

  defp ensure_adapter_started({adapter, id, args}, {supervisor, handlers}) do
    case handlers do
      %{^adapter => mfargs} ->
        retval =
          DynamicSupervisor.start_child(supervisor, %{
            id: adapter_name({adapter, id}),
            start: Kernel.put_elem(mfargs, 2, args),
            restart: :temporary
          })

        case retval do
          {:ok, pid} ->
            {:ok, pid}

          error ->
            :ok = Logger.error("Failed to start adapter for #{adapter}: #{inspect(error)}")
            {:error, :start_failed}
        end

      _ ->
        {:error, :no_handler}
    end
  end

  defp ensure_adapter_started({adapter, _id} = adapter_spec, {supervisor, handlers}) do
    case handlers do
      %{^adapter => mfargs} ->
        retval =
          DynamicSupervisor.start_child(supervisor, %{
            id: adapter_name(adapter_spec),
            start: mfargs,
            restart: :temporary
          })

        case retval do
          {:ok, pid} ->
            {:ok, pid}

          error ->
            :ok = Logger.error("Failed to start adapter for #{adapter}: #{inspect(error)}")
            {:error, :start_failed}
        end

      _ ->
        {:error, :no_handler}
    end
  end

  ## Callbacks
  ##

  @doc """
  Handles the call from the client API call/4.
  """
  @spec handle_call({:call, adapter(), call()}, from(), state()) :: reply({:ok, any()})
  def handle_call({:call, adapter_spec, func_spec}, _from, state) do
    case ensure_adapter_started(adapter_spec, state) do
      {:ok, pid} ->
        try do
          {:reply, {:ok, GenServer.call(pid, func_spec)}, state}
        after
          GenServer.stop(pid)
        end

      error ->
        {:reply, error, state}
    end
  end

  ## Client API
  ##

  @doc """
  Pass a tuple of `{function, arglist}` to the appropriate adapter.

  Returns `{:ok, response}` if the request was successful or
  `{:error, error_code}` in case of failure.
  """
  @spec call(call(), list()) :: resp({:ok, any()})
  def call(func_spec, opts \\ [])

  def call({:get_transactions, attrs}, opts) do
    Block.get_transactions(attrs, opts)
  end

  def call({:send, attrs}, opts) do
    Transaction.send(attrs, opts)
  end

  def call({:get_balances, attrs}, opts) do
    Balance.get(attrs, opts)
  end

  def call({:get_field, attrs}, opts) do
    Token.get_field(attrs, opts)
  end

  def call({:deposit_to_childchain, attrs}, opts) do
    Childchain.deposit(attrs, opts)
  end

  def call({:deploy_erc20, attrs}, opts) do
    Contract.deploy_erc20(attrs, opts)
  end

  def call(func_spec, opts) do
    with opts <- process_adapter_opts(opts),
         {:ok, resp} <-
           GenServer.call(
             opts[:eth_node_adapter_pid],
             {:call, opts[:eth_node_adapter], func_spec}
           ) do
      resp
    end
  end

  def childchain_call(func_spec, opts) do
    with opts <- process_adapter_opts(opts),
         {:ok, resp} <-
           GenServer.call(opts[:cc_node_adapter_pid], {:call, opts[:cc_node_adapter], func_spec}) do
      resp
    end
  end

  # TODO: change adapter / pid to opts
  def subscribe(
        :transaction,
        tx_hash,
        subscriber_pid,
        opts \\ []
      ) do
    :ok =
      BlockchainRegistry.start_listener(TransactionListener, %{
        id: tx_hash,
        interval: Application.get_env(:eth_blockchain, :transaction_poll_interval),
        blockchain_adapter_pid: opts[:cc_node_adapter_pid],
        node_adapter: opts[:cc_node_adapter]
      })

    BlockchainRegistry.subscribe(tx_hash, subscriber_pid)
  end

  def unsubscribe(:transaction, tx_hash, subscriber_pid) do
    BlockchainRegistry.unsubscribe(tx_hash, subscriber_pid)
  end

  def lookup_listener(id) do
    BlockchainRegistry.lookup(id)
  end

  defp process_adapter_opts(opts) do
    conf = Application.get_env(:eth_blockchain, EthBlockchain.Adapter)

    opts
    |> Keyword.put(:eth_node_adapter, opts[:eth_node_adapter] || conf[:default_eth_node_adapter])
    |> Keyword.put(:eth_node_adapter_pid, opts[:eth_node_adapter_pid] || __MODULE__)
    |> Keyword.put(:cc_node_adapter, opts[:cc_node_adapter] || conf[:default_cc_node_adapter])
    |> Keyword.put(:cc_node_adapter_pid, opts[:cc_node_adapter_pid] || __MODULE__)
  end
end
