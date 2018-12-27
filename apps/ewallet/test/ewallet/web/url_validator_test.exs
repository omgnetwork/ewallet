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

defmodule EWallet.Web.UrlValidatorTest do
  use EWallet.DBCase
  alias EWallet.Web.UrlValidator
  alias EWalletConfig.Config
  alias ActivityLogger.System

  describe "allowed_redirect_url?/1" do
    setup meta do
      {:ok, [redirect_url_prefixes: {:ok, _}]} =
        Config.update(
          [
            redirect_url_prefixes: [
              "https://example.com/allowed",
              "https://another.example.com/allowed"
            ],
            originator: %System{}
          ],
          meta[:config_pid]
        )

      :ok
    end

    test "returns true if the given url matches at least one of the prefixes" do
      assert UrlValidator.allowed_redirect_url?("https://example.com/allowed")
      assert UrlValidator.allowed_redirect_url?("https://another.example.com/allowed")
    end

    test "returns false if the given url matches none of the prefixes" do
      refute UrlValidator.allowed_redirect_url?("https://example.com")
      refute UrlValidator.allowed_redirect_url?("https://another.example.com")
      refute UrlValidator.allowed_redirect_url?("https://example.com/not-allowed")
      refute UrlValidator.allowed_redirect_url?("https://another.example.com/not-allowed")
    end
  end

  describe "allowed_redirect_url?/2 with a non-trailing slashed prefix" do
    setup do
      {:ok, %{allowed: "https://example.com"}}
    end

    test "returns true if the given url matches the prefix", meta do
      assert UrlValidator.allowed_redirect_url?("https://example.com", meta.allowed)
      assert UrlValidator.allowed_redirect_url?("https://example.com/", meta.allowed)
      assert UrlValidator.allowed_redirect_url?("https://example.com/segment", meta.allowed)
      assert UrlValidator.allowed_redirect_url?("https://example.com/segment/", meta.allowed)
    end

    test "returns false if the given url does not match the prefix", meta do
      refute UrlValidator.allowed_redirect_url?("https://something-else.com", meta.allowed)
      refute UrlValidator.allowed_redirect_url?("https://example.com@fake.com", meta.allowed)
      refute UrlValidator.allowed_redirect_url?("https://example.comfake.com", meta.allowed)
      refute UrlValidator.allowed_redirect_url?("https://example.com.fake.com", meta.allowed)
    end
  end

  describe "allowed_redirect_url?/2 with a trailing-slashed prefix" do
    setup do
      {:ok, %{allowed: "https://example.com/"}}
    end

    test "returns true if the given url matches the prefix", meta do
      assert UrlValidator.allowed_redirect_url?("https://example.com", meta.allowed)
      assert UrlValidator.allowed_redirect_url?("https://example.com/", meta.allowed)
      assert UrlValidator.allowed_redirect_url?("https://example.com/segment", meta.allowed)
      assert UrlValidator.allowed_redirect_url?("https://example.com/segment/", meta.allowed)
    end

    test "returns false if the given url does not match the prefix", meta do
      refute UrlValidator.allowed_redirect_url?("https://something-else.com", meta.allowed)
      refute UrlValidator.allowed_redirect_url?("https://example.com@fake.com", meta.allowed)
      refute UrlValidator.allowed_redirect_url?("https://example.comfake.com", meta.allowed)
      refute UrlValidator.allowed_redirect_url?("https://example.com.fake.com", meta.allowed)
    end
  end
end
