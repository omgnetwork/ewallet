defmodule AdminAPI.V1.InviteController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.UserView
  alias EWalletDB.Invite

  @doc """
  Validates the user's invite token and activates the user.
  """
  def accept(conn, %{
        "email" => email,
        "token" => token,
        "password" => password,
        "password_confirmation" => password_confirmation
      }) do
    email
    |> get_invite(token)
    |> validate_passwords(password, password_confirmation)
    |> Invite.accept(password)
    |> respond(conn)
  catch
    {:error, error_code} when is_atom(error_code) -> handle_error(conn, error_code)
  end

  def accept(conn, _), do: handle_error(conn, :invalid_parameter)

  defp get_invite(email, token) do
    case Invite.get(email, token) do
      %Invite{} = invite -> invite
      _ -> throw({:error, :invite_not_found})
    end
  end

  defp validate_passwords(invite, password, password_confirmation) do
    if password == password_confirmation do
      invite
    else
      throw({:error, :passwords_mismatch})
    end
  end

  defp respond({:ok, invite}, conn) do
    render(conn, UserView, :user, %{user: invite.user})
  end

  defp respond({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end
end
