defmodule EWallet.Web.UrlValidatorTest do
  use EWallet.DBCase
  alias EWallet.Web.UrlValidator
  alias EWalletConfig.Config
  alias ActivityLogger.System

  describe "allowed_redirect_url?/1" do
    test "returns true if the given url has the whitelisted prefix", meta do
      {:ok, [redirect_url_prefixes: {:ok, _}]} =
        Config.update(
          [
            redirect_url_prefixes: ["http://test_redirect_prefix"],
            originator: %System{}
          ],
          meta[:config_pid]
        )

      assert UrlValidator.allowed_redirect_url?("http://test_redirect_prefix/allowed")
    end

    test "returns true if the given url is prefixed with the base url" do
      assert UrlValidator.allowed_redirect_url?("http://localhost:4000/allowed")
    end

    test "returns false if the given url is not in the whitelisted prefixes" do
      refute UrlValidator.allowed_redirect_url?("http://something-else.com/allowed")
    end
  end
end
