defmodule KuberaDB.Helpers.CryptoTest do
  use ExUnit.Case
  alias KuberaDB.Helpers.Crypto

  describe "generate_key/1" do
    test "returns a key with the specified length" do
      key = Crypto.generate_key(32)
      assert String.length(key) == 32

      # Test with another length to make sure it's not hardcoded.
      key = Crypto.generate_key(64)
      assert String.length(key) == 64
    end
  end
end
