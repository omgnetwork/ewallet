defmodule EWalletDB.Repo.Seeds.UserSampleSeed do
  alias EWalletDB.User

  @users_count 5
  @username_prefix "user"
  @provider_prefix "provider_user_id"

  def seed do
    [
      run_banner: "Seeding sample eWallet users:",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    Enum.each 1..@users_count, fn n ->
      run_with(writer, n)
    end
  end

  def run_with(writer, n) do
    running_string = n |> to_string() |> String.pad_leading(2, "0")

    data = %{
      provider_user_id: @provider_prefix <> running_string,
      username: @username_prefix <> running_string,
      metadata: %{}
    }

    case User.get_by_provider_user_id(data.provider_user_id) do
      nil ->
        case User.insert(data) do
          {:ok, user} ->
            writer.success("""
              User ID          : #{user.id}
              Provider user ID : #{user.provider_user_id}
              Username         : #{user.username}
            """)
          {:error, changeset} ->
            writer.error("  eWallet user #{data.email} could not be inserted:")
            writer.print_errors(changeset)
          _ ->
            writer.error("  eWallet user #{data.email} could not be inserted:")
            writer.error("  Unknown error.")
        end
      %User{} = user ->
        writer.warn("""
          User ID          : #{user.id}
          Provider user ID : #{user.provider_user_id}
          Username         : #{user.username}
        """)
    end
  end
end
