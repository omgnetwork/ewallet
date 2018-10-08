defmodule EWalletDB.Repo.Seeds.UserSampleSeed do
  alias Ecto.UUID
  alias EWallet.TransactionGate
  alias EWalletDB.{Account, AccountUser, System, Token, User}

  @users_count 5
  @username_prefix "user"
  @provider_prefix "provider_user_id"
  @minimum_token_amount 1_000

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
      metadata: %{},
      account_uuid: Account.get_master_account().uuid,
      originator: %System{}
    }

    case User.get_by_provider_user_id(data.provider_user_id) do
      nil ->
        case User.insert(data) do
          {:ok, user} ->
            :ok = give_token(user, Token.all(), @minimum_token_amount)
            {:ok, _} = AccountUser.link(data.account_uuid, user.uuid)

            writer.success("""
              User ID          : #{user.id}
              Provider user ID : #{user.provider_user_id}
              Username         : #{user.username}
            """)

          {:error, changeset} ->
            writer.error("  eWallet user #{data.username} could not be inserted:")
            writer.print_errors(changeset)

          _ ->
            writer.error("  eWallet user #{data.username} could not be inserted:")
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

  defp give_token(user, tokens, minimum_amount) when is_list(tokens) do
    Enum.each(tokens, fn token ->
      give_token(user, token, minimum_amount)
    end)
  end

  defp give_token(user, token, minimum_amount) do
    master_account = Account.get_master_account()

    TransactionGate.create(%{
      "from_address" => Account.get_primary_wallet(master_account).address,
      "to_address" => User.get_primary_wallet(user).address,
      "token_id" => token.id,
      "amount" => :rand.uniform(10) * minimum_amount * token.subunit_to_unit,
      "metadata" => %{},
      "idempotency_token" => UUID.generate()
    })
  end
end
