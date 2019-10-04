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
  @moduledoc """
  This is the entry point to interact with the ethereum blockchain and its childchains.
  """

  @typep call :: EthBlockchain.call()
  @typep resp(ret) :: ret | {:error, atom()}

  alias EthBlockchain.{
    AdapterServer,
    Balance,
    Block,
    Contract,
    Childchain,
    DumbAdapter,
    DumbReceivingAdapter,
    ErrorHandler,
    Helper,
    GasHelper,
    Token,
    Transaction,
    TransactionListener,
    BlockchainRegistry,
    Status
  }

  def helper, do: Helper
  def gas_helper, do: GasHelper
  def error_handler, do: ErrorHandler
  def dumb_adapter, do: DumbAdapter
  def dumb_receiving_adapter, do: DumbReceivingAdapter
  def server, do: AdapterServer

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

  def call({:get_block, attrs}, opts) do
    Block.get(attrs, opts)
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

  def call({:deploy_erc20, attrs}, opts) do
    Contract.deploy_erc20(attrs, opts)
  end

  def call({:mint_erc20, attrs}, opts) do
    Transaction.mint_erc20(attrs, opts)
  end

  def call({:lock_erc20, attrs}, opts) do
    Transaction.lock_erc20(attrs, opts)
  end

  def call({:is_erc20_locked, attrs}, opts) do
    Token.locked?(attrs, opts)
  end

  def call({:deposit_to_childchain, attrs}, opts) do
    Childchain.deposit(attrs, opts)
  end

  def call({:transfer_on_childchain, attrs}, opts) do
    Childchain.send(attrs, opts)
  end

  def call({:get_childchain_balance, attrs}, opts) do
    Childchain.get_balance(attrs, opts)
  end

  def call({:get_childchain_contract_address, _attrs}, opts) do
    AdapterServer.childchain_call({:get_contract_address}, opts)
  end

  def call({:get_status, _attrs}, opts) do
    Status.get_status(opts)
  end

  def subscribe(:transaction, tx_hash, is_childchain_transaction, subscriber_pid, opts \\ []) do
    :ok =
      BlockchainRegistry.start_listener(TransactionListener, %{
        id: tx_hash,
        is_childchain_transaction: is_childchain_transaction,
        interval: Application.get_env(:eth_blockchain, :transaction_poll_interval),
        blockchain_adapter_pid: opts[:eth_node_adapter_pid],
        node_adapter: opts[:eth_node_adapter]
      })

    BlockchainRegistry.subscribe(tx_hash, subscriber_pid)
  end

  def unsubscribe(:transaction, tx_hash, subscriber_pid) do
    BlockchainRegistry.unsubscribe(tx_hash, subscriber_pid)
  end

  def lookup_listener(tx_hash) do
    BlockchainRegistry.lookup(tx_hash)
  end
end
