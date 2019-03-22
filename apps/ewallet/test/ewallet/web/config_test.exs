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

  describe "cors_plug_config/0" do
    test "returns a restricted config when no CORS_ORIGIN and no CORS_MAX_AGE specified" do
      config = Config.cors_plug_config()

      assert config[:max_age] == 600
      assert config[:origin] == []

      assert config[:headers] == [
               "Authorization",
               "Content-Type",
               "Accept",
               "Origin",
               "User-Agent",
               "DNT",
               "Cache-Control",
               "X-Mx-ReqToken",
               "Keep-Alive",
               "X-Requested-With",
               "If-Modified-Since",
               "X-CSRF-Token",
               "OMGAdmin-Account-ID"
             ]

      assert config[:methods] == ["POST", "GET"]
    end

    test "returns a correct max_age value when CORS_MAX_AGE is specified" do
      max_age = 1234
      {:ok, original_env} = set_system_env("CORS_MAX_AGE", max_age)

      config = Config.cors_plug_config()

      assert config[:max_age] == max_age

      # Revert the env var to their original values.
      {:ok, _} = set_system_env("CORS_MAX_AGE", original_env)
    end

    test "returns a correct origin value when CORS_ORIGIN is specified with a single value" do
      origin = "http://example.com"
      {:ok, original_env} = set_system_env("CORS_ORIGIN", origin)

      config = Config.cors_plug_config()

      assert config[:origin] == [origin]

      # Revert the env var to their original values.
      {:ok, _} = set_system_env("CORS_ORIGIN", original_env)
    end

    test "returns a correct origin value when CORS_ORIGIN is specified with multiple values" do
      origin = "http://example.com, http://localhost.com"
      {:ok, original_env} = set_system_env("CORS_ORIGIN", origin)

      config = Config.cors_plug_config()

      assert config[:origin] == ["http://example.com", "http://localhost.com"]

      # Revert the env var to their original values.
      {:ok, _} = set_system_env("CORS_ORIGIN", original_env)
    end
  end
end
