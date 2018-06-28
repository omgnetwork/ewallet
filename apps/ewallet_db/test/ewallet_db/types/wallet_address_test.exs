defmodule EWalletDB.Types.WalletAddressTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.Types.WalletAddress
  alias EWalletDB.Wallet

  describe "cast/1" do
    test "casts input to lower case" do
      assert WalletAddress.cast("ABCD-123456789012") == {:ok, "abcd123456789012"}
    end

    test "strips all non-alphanumerics" do
      assert WalletAddress.cast("abcd%1234/5678_9012") == {:ok, "abcd123456789012"}
    end

    test "accepts inputs with all integers" do
      assert WalletAddress.cast("1234123456789012") == {:ok, "1234123456789012"}
    end

    test "returns error if any of the 12 latter characters consist of non-integers" do
      assert WalletAddress.cast("abcd-1234-5678-901X") == :error
      assert WalletAddress.cast("abcd-1234-5XX8-9012") == :error
    end

    test "returns error if the input has invalid length" do
      assert WalletAddress.cast("abcd1234") == :error
      assert WalletAddress.cast("abcd1234567890123") == :error
    end
  end

  describe "load/1" do
    # The wallet address is stored as string in the database,
    # so no transformation needed.
    test "returns the same string" do
      assert WalletAddress.load("abcd123456789012") == {:ok, "abcd123456789012"}
    end
  end

  describe "dump/1" do
    # The wallet address should have already been casted via `cast/1`
    # to a uniformed format. So no transformation needed.
    test "returns the same string" do
      assert WalletAddress.dump("abcd123456789012") == {:ok, "abcd123456789012"}
    end
  end

  describe "wallet_address/2" do
    test "populates the schema with a valid wallet address" do
      {:ok, wallet} =
        :wallet
        |> params_for(address: nil)
        |> Wallet.insert()

      assert String.match?(wallet.address, ~r/^[a-z]{4}[0-9]{12}$/)
    end

    test "uses the given wallet address if provided" do
      {:ok, wallet} =
        :wallet
        |> params_for(address: "test-1234-5678-9012")
        |> Wallet.insert()

      assert wallet.address == "test123456789012"
    end
  end

  describe "generate/1" do
    test "returns {:ok, address}" do
      {:ok, address} = WalletAddress.generate()
      assert String.match?(address, ~r/^[a-z]{4}[0-9]{12}$/)
    end

    test "returns {:ok, address} when prefix is provided" do
      {:ok, address} = WalletAddress.generate("abcd")
      assert String.match?(address, ~r/^abcd[0-9]{12}$/)
    end

    test "returns {:ok, address} when prefix less than 4 characters are provided" do
      {:ok, address} = WalletAddress.generate("ab")
      assert String.match?(address, ~r/^ab[0-9]{2}[0-9]{12}$/)
    end

    test "returns {:ok, address} when the prefix contains numbers" do
      {:ok, address} = WalletAddress.generate("9999")
      assert String.match?(address, ~r/^9999[0-9]{12}$/)
    end

    test "returns :error if prefix contains invalid character" do
      assert WalletAddress.generate("abc%") == :error
      assert WalletAddress.generate("____") == :error
    end
  end

  describe "autogenerate/1" do
    test "returns a wallet address ID" do
      address = WalletAddress.autogenerate("abcd")
      assert String.match?(address, ~r/^abcd[0-9]{12}$/)
    end
  end
end
