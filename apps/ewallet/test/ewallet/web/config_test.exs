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

defmodule EWallet.Web.ConfigTest do
  # `async: false` since the tests require `Application.put_env/3`.
  use ExUnit.Case, async: false
  alias EWallet.Web.Config

  # Take note of the original config value, then delete it.
  defp set_system_env(key, nil) do
    original = System.get_env(key)
    {System.delete_env(key), original}
  end

  # Take note of the original config value, then update it.
  defp set_system_env(key, value) when not is_binary(value) do
    set_system_env(key, to_string(value))
  end

  defp set_system_env(key, value) do
    original = System.get_env(key)
    {System.put_env(key, value), original}
  end

  # Take note of the original config value, then delete it.
  defp delete_config(app, key) do
    original = Application.get_env(app, key)
    {Application.delete_env(app, key), original}
  end

  describe "configure_cors_plug/0" do
    test "sets CORS_MAX_AGE to :max_age" do
      new_env = 1234
      {:ok, original_env} = set_system_env("CORS_MAX_AGE", new_env)
      {:ok, original_config} = delete_config(:cors_plug, :max_age)

      # Invoke & assert
      res = Config.configure_cors_plug()
      assert res == :ok
      assert Application.get_env(:cors_plug, :max_age) == new_env

      # Revert the env var and app config to their original values.
      :ok = Application.put_env(:cors_plug, :max_age, original_config)
      {:ok, _} = set_system_env("CORS_MAX_AGE", original_env)
    end

    test "sets the :headers to a list" do
      {:ok, original_config} = delete_config(:cors_plug, :headers)

      # Invoke & assert
      res = Config.configure_cors_plug()
      assert res == :ok
      assert is_list(Application.get_env(:cors_plug, :headers))

      # Revert the app config to its original value.
      :ok = Application.put_env(:cors_plug, :headers, original_config)
    end

    test "sets the :methods to [\"POST\"]" do
      {:ok, original_config} = delete_config(:cors_plug, :methods)

      # Invoke & assert
      res = Config.configure_cors_plug()
      assert res == :ok
      assert is_list(Application.get_env(:cors_plug, :headers))

      # Revert the app config to its original value.
      :ok = Application.put_env(:cors_plug, :headers, original_config)
    end

    test "sets CORS_ORIGIN to :origin" do
      new_env = "https://example.com, https://second.example.com"
      new_parsed_env = ["https://example.com", "https://second.example.com"]

      {:ok, original_env} = set_system_env("CORS_ORIGIN", new_env)
      {:ok, original_config} = delete_config(:cors_plug, :origin)

      # Invoke & assert
      res = Config.configure_cors_plug()
      assert res == :ok
      assert Application.get_env(:cors_plug, :origin) == new_parsed_env

      # Revert the env var and app config to their original values.
      :ok = Application.put_env(:cors_plug, :origin, original_config)
      {:ok, _} = set_system_env("CORS_ORIGIN", original_env)
    end
  end
end
