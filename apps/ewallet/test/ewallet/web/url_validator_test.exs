defmodule EWallet.Web.UrlValidatorTest do
  use ExUnit.Case
  alias EWallet.Web.UrlValidator

  describe "allowed_redirect_url?/1" do
    test "returns true if the given url has the whitelisted prefix" do
      assert UrlValidator.allowed_redirect_url?("http://localhost:4000/allowed")
    end

    test "returns false if the given url is not in the whitelisted prefixes" do
      refute UrlValidator.allowed_redirect_url?("http://something-else.com/allowed")
    end
  end
end
