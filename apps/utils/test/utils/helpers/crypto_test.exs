defmodule Utils.Helpers.CryptoTest do
  use ExUnit.Case
  alias Utils.Helpers.Crypto

  describe "generate_base64_key/1" do
    test "returns a key with the specified length" do
      key = Crypto.generate_base64_key(32)
      # ceil(32 * 4 / 3)
      assert String.length(key) == 43

      # Test with another length to make sure it's not hardcoded.
      key = Crypto.generate_base64_key(64)
      # ceil(64 * 4 / 3)
      assert String.length(key) == 86
    end
  end
end
