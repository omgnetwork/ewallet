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

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(
          UserChannel,
          topic(user.id)
        )
        |> assert_success(topic(user.id))
      end)
    end

    test "can join the channel of a valid provider user ID" do
      {:ok, user} = :user |> params_for() |> User.insert()

      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(
          UserChannel,
          topic(user.provider_user_id)
        )
        |> assert_success(topic(user.provider_user_id))
      end)
    end

    test "can't join the channel of an inexisting user" do
      test_with_auths(fn auth ->
        auth
        |> subscribe_and_join(
          UserChannel,
          topic(UUID.generate())
        )
        |> assert_failure(:forbidden_channel)
      end)
    end
  end
end
