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

defmodule EthOmisegoNetworkAdapter.Balance do
  @moduledoc """
  Interface with balances on plasma chain.
  """
  alias EthOmisegoNetworkAdapter.HttpClient

  @doc """
  Retrieve the balance of the specified address on the plasma chain.
  Returns:
  {:ok,
    %{
      "0xtoken_1" => int_amount_1,
      "0xtoken_2" => int_amount_2,
    }
  } if success
  {:error, code} || {:error, code, params} if there was an error while communicating with
  the watcher.
  """
  @spec get(Sting.t()) ::
          {:ok, map()} | {:error, atom()} | {:error, atom(), any()}
  def get(address) do
    %{address: address}
    |> Jason.encode!()
    |> HttpClient.post_request("account.get_balance")
    |> respond()
  end

  defp respond({:ok, balances}) do
    balances =
      Enum.reduce(balances, %{}, fn %{"amount" => amount, "currency" => currency}, acc ->
        Map.put(acc, currency, amount)
      end)

    {:ok, balances}
  end

  defp respond(error), do: error
end
