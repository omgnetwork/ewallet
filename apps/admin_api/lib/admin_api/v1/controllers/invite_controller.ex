defmodule AdminAPI.V1.InviteController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.UserView
  alias EWallet.Web.Preloader
  alias EWalletDB.{Invite, User}

  @doc """
  Validates the user's invite token and activates the user.
  """
  @spec accept(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def accept(conn, %{
        "email" => email,
        "token" => token,
        "password" => password,
        "password_confirmation" => password_confirmation
      }) do
    with %Invite{} = invite <- Invite.get(email, token) || {:error, :invite_not_found},
         true <- password == password_confirmation || {:error, :passwords_mismatch},
         {:ok, invite} <- Preloader.preload_one(invite, :user),
         {:ok, _} <- Invite.accept(invite, password),
         {:ok, _} <- User.set_admin(invite.user, true) do
      render(conn, UserView, :user, %{user: invite.user})
    else
      {:error, error_code} when is_atom(error_code) ->
        handle_error(conn, error_code)

      {:error, changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end

  def accept(conn, _) do
    handle_error(
      conn,
      :invalid_parameter,
      "Invalid parameter provided. `email`, `token`, `password`, `password_confirmation` are required."
    )
  end
end
