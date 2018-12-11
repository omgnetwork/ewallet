# credo:disable-for-this-file
defmodule EWalletAPI.V1.UserChannelTest do
  use EWalletAPI.ChannelCase, async: false
  alias EWalletAPI.V1.UserChannel

  defp topic(id), do: "user:#{id}"

  describe "join/3 as client" do
    test "joins the channel with authenticated user and same user (using id)" do
      user = get_test_user()

      user.id
      |> topic()
      |> test_with_topic(UserChannel)
      |> assert_success(topic(user.id))
    end

    test "joins the channel with authenticated user and same user (using provider_user_id)" do
      user = get_test_user()

      user.provider_user_id
      |> topic()
      |> test_with_topic(UserChannel)
      |> assert_success(topic(user.provider_user_id))
    end

    test "can't join channel with existing different user (using id)" do
      user = insert(:user)

      user.id
      |> topic()
      |> test_with_topic(UserChannel)
      |> assert_failure(:forbidden_channel)
    end

    test "can't join channel with existing different user (using provider_user_id)" do
      user = insert(:user)

      user.provider_user_id
      |> topic()
      |> test_with_topic(UserChannel)
      |> assert_failure(:forbidden_channel)
    end

    test "can't join channel with inexisting user" do
      "usr_123"
      |> topic()
      |> test_with_topic(UserChannel)
      |> assert_failure(:forbidden_channel)
    end
  end
end
