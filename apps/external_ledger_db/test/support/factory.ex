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

defmodule ExternalLedgerDB.Factory do
  @moduledoc """
  Factories used for testing.
  """
  use ExMachina.Ecto, repo: ExternalLedgerDB.Repo
  alias ExternalLedgerDB.Wallet

  def wallet_factory do
    %Wallet{
      address: sequence("address"),
      adapter: Wallet.ethereum(),
      type: Wallet.hot(),
      public_key: sequence("public_key_")
    }
  end
end
