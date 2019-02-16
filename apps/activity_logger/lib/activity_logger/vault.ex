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

defmodule ActivityLogger.Vault do
  @moduledoc false

  use Cloak.Vault, otp_app: :activity_logger

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
    "EWALLET_SECRET_KEY"
    |> System.get_env()
    |> Base.decode64!()
  end

  defp secret_key(_) do
    <<126, 194, 0, 33, 217, 227, 143, 82, 252, 80, 133, 89, 70, 211, 139, 150, 209, 103, 94, 240,
      194, 108, 166, 100, 48, 144, 207, 242, 93, 244, 27, 144>>
  end
end
