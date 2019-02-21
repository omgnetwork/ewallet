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

defmodule Blockchain.Wallet do
  @moduledoc false

  alias Blockchain.Backend

  @typep address :: Blockchain.address()
  @typep resp(ret) :: ret | {:error, atom()}

  @doc """
  Generates a new wallet address for the given blockchain adapter and return
  a wallet ID for futher access. The blockchain adapter will responsible
  for managing the wallet key and blockchain operations.

  Returns a tuple of `{:ok, {backend, wallet_id, public_key}}` in case of
  a successful wallet generation otherwise returns `{:error, error_code}`.
  """
  @spec generate_wallet(atom(), pid() | nil) :: resp({:ok, address()})
  @spec generate_wallet(atom()) :: resp({:ok, address()})
  def generate_wallet(backend, pid \\ nil) do
    case pid do
      nil ->
        Backend.call(backend, :generate_wallet)

      p when is_pid(p) ->
        Backend.call(backend, :generate_wallet, p)
    end
  end
end
