defmodule AdminAPI.V1.AccountMembershipController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.Inviter
  alias EWalletDB.{Account, Membership, Role, User}

  @doc """
  Lists the users that are assigned to the given account.
  """
  def get_users(conn, %{"account_id" => account_id}) do
    get_users(conn, Account.get(account_id, preload: [memberships: [:user, :role]]))
  end

  def get_users(conn, %Account{} = account) do
    render(conn, :memberships, %{memberships: account.memberships})
  end

  def get_users(conn, nil), do: handle_error(conn, :account_id_not_found)
  def get_users(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Assigns the user to the given account and role.
  """
  def assign_user(
        conn,
        %{
          "account_id" => account_id,
          "role_name" => role_name,
          "redirect_url" => redirect_url
        } = attrs
      ) do
    with user <- get_user_or_email(attrs),
         {false, :user_id_not_found} <- {is_tuple(user), :user_id_not_found},
         %Account{} = account <- Account.get(account_id) || {:error, :account_id_not_found},
         %Role{} = role <- Role.get_by_name(role_name) || {:error, :role_name_not_found},
         {:ok, _} <- assign_or_invite(user, account, role, redirect_url) do
      render(conn, :empty, %{success: true})
    else
      {true, :user_id_not_found} ->
        handle_error(conn, :user_id_not_found)

      {:error, code} when is_atom(code) ->
        handle_error(conn, code)

      # Matches a different error format returned by Membership.assign_user/2
      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  def assign_user(conn, _attrs), do: handle_error(conn, :invalid_parameter)

  # Get user or email specifically for `assign_user/2` above.
  #
  # Returns:
  # - `%User{}` if user_id is provided and found.
  # - `:user_id_not_found` if `user_id` is provided but not found.
  # - `%User{}` if email is provided and found.
  # - `string` email if email provided but not found.
  #
  # If both `user_id` and `email` are provided, only `user_id` is attempted.
  # Hence the pattern matching for `%{"user_id" => _}` comes first.
  defp get_user_or_email(%{"user_id" => user_id}) do
    case User.get(user_id) do
      %User{} = user -> user
      _ -> {:error, :user_id_not_found}
    end
  end

  defp get_user_or_email(%{"email" => email}) do
    case User.get_by_email(email) do
      %User{} = user -> user
      nil -> email
    end
  end

  defp assign_or_invite(email, account, role, redirect_url) when is_binary(email) do
    Inviter.invite(email, account, role, redirect_url)
  end

  defp assign_or_invite(user, account, role, redirect_url) do
    case User.get_status(user) do
      :pending_confirmation ->
        user
        |> User.get_invite()
        |> Inviter.send_email(redirect_url)

      :active ->
        Membership.assign(user, account, role)
    end
  end

  @doc """
  Unassigns the user from the given account.
  """
  def unassign_user(conn, %{
        "user_id" => user_id,
        "account_id" => account_id
      }) do
    with %User{} = user <- User.get(user_id) || {:error, :user_id_not_found},
         %Account{} = account <- Account.get(account_id) || {:error, :account_id_not_found},
         {:ok, _} <- Membership.unassign(user, account) do
      render(conn, :empty, %{success: true})
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  def unassign_user(conn, _attrs), do: handle_error(conn, :invalid_parameter)
end
