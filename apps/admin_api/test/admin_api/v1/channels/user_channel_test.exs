# credo:disable-for-this-file
defmodule AdminAPI.V1.UserChannelTest do
  use AdminAPI.ChannelCase, async: false
  alias AdminAPI.V1.UserChannel
  alias EWalletDB.User
  alias Ecto.UUID

  defp topic(id), do: "user:#{id}"

  describe "join/3" do
    test "can join the channel of a valid user ID" do
      {:ok, user} = :user |> params_for() |> User.insert()

      topic = topic(user.id)

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(UserChannel, topic)
        |> assert_success(topic)
      end)
    end

    test "can join the channel of a valid provider user ID" do
      {:ok, user} = :user |> params_for() |> User.insert()
      topic = topic(user.provider_user_id)

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(
          UserChannel,
          topic
        )
        |> assert_success(topic)
      end)
    end

    test "can't join the channel of an inexisting user" do
      topic = topic(UUID.generate())

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(UserChannel, topic)
        |> assert_failure(:forbidden_channel)
      end)
    end
  end
end
