# credo:disable-for-this-file
defmodule EWalletAPI.V1.TransactionRequestChannelTest do
  use EWalletAPI.ChannelCase, async: false
  alias EWalletAPI.V1.TransactionRequestChannel
  alias EWalletDB.User

  defp topic(id), do: "transaction_request:#{id}"

  describe "join/3 as client" do
    test "can join the channel with authenticated user and owned request" do
      user = get_test_user()
      wallet = User.get_primary_wallet(user)
      request = insert(:transaction_request, wallet: wallet)

      request.id
      |> topic()
      |> test_with_topic(TransactionRequestChannel)
      |> assert_success(topic(request.id))
    end

    test "can't join channel with existing not owned address" do
      request = insert(:transaction_request)

      request.id
      |> topic()
      |> test_with_topic(TransactionRequestChannel)
      |> assert_failure(:forbidden_channel)
    end

    test "can't join channel with inexisting request" do
      "123"
      |> topic()
      |> test_with_topic(TransactionRequestChannel)
      |> assert_failure(:forbidden_channel)
    end
  end
end
