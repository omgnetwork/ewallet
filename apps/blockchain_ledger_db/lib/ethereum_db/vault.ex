# Copyright 2017-2019 OmiseGO Pte Ltd
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

defmodule BlockchainLedgerDB.Vault do
  @moduledoc false
  use Cloak.Vault, otp_app: :blockchain_ledger_db

  @impl GenServer
  def init(config) do
    env = Application.get_env(:ewallet, :env)

    config =
      Keyword.put(
        config,
        :ciphers,
        default: {
          Cloak.Ciphers.AES.GCM,
          tag: "AES.GCM.V1", key: secret_key(env)
        }
      )

    {:ok, config}
  end

  defp secret_key(t) when is_binary(t) do
    t
    |> String.to_atom()
    |> secret_key()
  end

  defp secret_key(:prod) do
    "LOCAL_LEDGER_SECRET_KEY"
    |> System.get_env()
    |> Base.decode64!()
  end

  defp secret_key(_) do
    <<81, 98, 218, 231, 73, 11, 210, 156, 118, 252, 177, 144, 224, 97, 197, 156, 196, 13, 183, 9,
      154, 170, 231, 61, 6, 26, 166, 46, 16, 246, 150, 61>>
  end
end
