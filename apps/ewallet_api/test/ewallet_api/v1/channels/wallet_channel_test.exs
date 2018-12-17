# credo:disable-for-this-file
defmodule EWalletAPI.V1.WalletChannelTest do
  use EWalletAPI.ChannelCase, async: false
  alias EWalletAPI.V1.WalletChannel
  alias EWalletDB.User

  defp topic(address), do: "address:#{address}"

  describe "join/3 as client" do
    test "Can join the channel with authenticated user and owned address" do
      wallet = User.get_primary_wallet(get_test_user())

      wallet.address
      |> topic()
      |> test_with_topic(WalletChannel)
      |> assert_success(topic(wallet.address))
    end

    test "can't join channel with existing not owned address" do
      wallet = insert(:wallet)

      wallet.address
      |> topic()
      |> test_with_topic(WalletChannel)
      |> assert_failure(:forbidden_channel)
    end

    test "can't join channel with inexisting address" do
      "none000000000000"
      |> topic()
      |> test_with_topic(WalletChannel)
      |> assert_failure(:forbidden_channel)
    end
  end
end
