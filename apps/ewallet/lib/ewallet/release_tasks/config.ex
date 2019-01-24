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

defmodule EWallet.ReleaseTasks.Config do
  @moduledoc """
  A release task that manages application configurations.
  """
  use EWallet.ReleaseTasks
  alias ActivityLogger.System
  alias EWallet.CLI
  alias EWalletConfig.Config

  @start_apps [:crypto, :ssl, :postgrex, :ecto, :cloak, :ewallet]
  @apps [:activity_logger, :ewallet_config]

  def run do
    case :init.get_plain_arguments() do
      [key, value] ->
        config_base64(key, value)

      _ ->
        give_up()
    end
  end

  def run(key, value), do: config_base64(key, value)

  defp config_base64(k, v) when is_list(k) do
    case Base.decode64(to_string(k)) do
      {:ok, key} ->
        config_base64(key, v)

      _ ->
        give_up()
    end
  end

  defp config_base64(k, v) when is_list(v) do
    case Base.decode64(to_string(v)) do
      {:ok, value} ->
        config_base64(k, value)

      _ ->
        give_up()
    end
  end

  defp config_base64(key, value) do
    Enum.each(@start_apps, &Application.ensure_all_started/1)
    Enum.each(@apps, &ensure_app_started/1)

    case Config.update(%{key => value, originator: %System{}}) do
      {:ok, [{key, {:ok, _}}]} ->
        CLI.success("Successfully updated \"#{key}\" to \"#{value}\"")
        :init.stop()

      {:ok, [{key, {:error, :setting_not_found}}]} ->
        CLI.error("Error: \"#{key}\" is not a valid settings")
        :init.stop(1)

      _ ->
        give_up()
    end
  end
end
