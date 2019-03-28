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

  # Take note of the original config value, then update it.
  defp set_env(key, value) do
    original = Application.get_env(:ewallet, key)
    {Application.put_env(:ewallet, key, value), original}
  end

  describe "cors_plug_config/0" do
    test "returns the default :headers and :methods" do
      config = Config.cors_plug_config()

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

    test "returns the correct :cors_max_age value" do
      config = Config.cors_plug_config()

      assert config[:max_age] == 86_400
    end

    test "returns the correct :cors_origin value when there is only one origin" do
      origin = "http://example.com"
      {:ok, original_env} = set_env(:cors_origin, origin)
      config = Config.cors_plug_config()

      assert config[:origin].() == [origin]

      # Revert the env var to their original values.
      {:ok, _} = set_env(:cors_originn, original_env)
    end

    test "returns the correct :cors_origin values when there are multiple origins" do
      origin = "https://example.com, https://second.example.com"
      {:ok, original_env} = set_env(:cors_origin, origin)
      config = Config.cors_plug_config()

      assert config[:origin].() == ["https://example.com", "https://second.example.com"]

      # Revert the env var to their original values.
      {:ok, _} = set_env(:cors_origin, original_env)
    end
  end
end
