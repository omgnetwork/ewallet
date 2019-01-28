# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWalletDB.Repo.Reporters.SeedsSettingsReporter do
  alias EWalletConfig.Config

  def run(writer, _args) do
    writer.heading("eWallet Settings")
    writer.print("""
    Here is your current list of settings and their values:

    """)

    Enum.each(Config.settings(), fn setting ->
      writer.print("""
        #{setting.position}. #{setting.key} (#{setting.type}): #{inspect_value(setting)}
      """)
    end)

    writer.print("""

    Settings seed has completed successfully!
    You can update those values using the Admin API.
    """)
  end

  defp inspect_value(%{value: nil, type: _}), do: "nil"
  defp inspect_value(%{value: value, type: "array"}), do: ~s([#{Enum.join(value, ", ")}])
  defp inspect_value(%{value: value, type: "map"}), do: inspect(value)
  defp inspect_value(%{value: value, type: "string"}), do: ~s("#{value}")
  defp inspect_value(%{value: value, type: "boolean"}), do: value
  defp inspect_value(%{value: value, type: "integer"}), do: value
end
