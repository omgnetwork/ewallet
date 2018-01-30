defmodule AdminAPI.V1.InviteController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.UserView
  alias EWalletDB.Invite

  @doc """
  Validates the user's invite token and activates the user.
  """
  def accept(conn, %{
    "email"            => email,
    "token"            => token,
    "password"         => password,
    "password_confirm" => password_confirm,
  }) do
    email
    |> get_invite(token)
    |> validate_passwords(password, password_confirm)
    |> Invite.accept(password)
    |> respond(conn)
  catch
    {:error, error_code} when is_atom(error_code) -> handle_error(conn, error_code)
  end

  defp get_invite(email, token) do
    case Invite.get(email, token) do
      %Invite{} = invite -> invite
                       _ -> throw {:error, :invite_not_found}
    end
  end

  defp validate_passwords(invite, password, password_confirm) do
    if password == password_confirm do
      invite
    else
      throw {:error, :passwords_mismatch}
    end
  end

  defp respond({:ok, invite}, conn) do
    render(conn, UserView, :user, %{user: invite.user})
  end

  defp respond({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end
end
