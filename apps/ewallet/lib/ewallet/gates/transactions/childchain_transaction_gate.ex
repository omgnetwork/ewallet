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

defmodule EWallet.ChildchainTransactionGate do
  @moduledoc """
  This is an intermediary module that formats the params so they can be processed by
  the BlockchainTransactionGate
  """
  alias EWallet.{BlockchainTransactionGate, BlockchainHelper}
  alias EWalletDB.Transaction

  def deposit(actor, %{"amount" => amount} = attrs) when is_integer(amount) do
    attrs = build_transaction_attrs(attrs)
    validation_tuple = address_validation_tuple(attrs)
    BlockchainTransactionGate.create(actor, attrs, validation_tuple)
  end

  def deposit(_, _) do
    {:error, :invalid_parameter, "Invalid parameter provided. `amount` is required."}
  end

  defp build_transaction_attrs(%{"address" => address} = attrs) do
    {:ok, contract_address} = BlockchainHelper.call(:get_childchain_contract_address)

    attrs
    |> Map.put("from_address", address)
    |> Map.put("to_address", contract_address)
    |> Map.delete("address")
    |> Map.put("type", Transaction.deposit())
  end

  defp address_validation_tuple(attrs) do
    {
      BlockchainHelper.validate_blockchain_address(attrs["from_address"]) == :ok,
      BlockchainHelper.validate_blockchain_address(attrs["to_address"]) == :ok
    }
  end
end
