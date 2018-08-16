defmodule EWalletAPI.V1.SignupController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias Ecto.Changeset
  alias EWallet.UserPolicy
  alias EWallet.Web.Preloader
  alias EWalletDB.Invite

  @doc """
  Signs up a new user.

  This function is used when the eWallet is setup as a standalone solution,
  allowing users to sign up without an integration with the provider's server.
  """
  @spec signup(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def signup(conn, attrs) do
    with :ok <- permit(:create, conn.assigns, nil),
         {:ok, invite} <- SignupGate.signup(attrs) do
      render(conn, :empty, %{success: true})
    else
      {:error, code} ->
        handle_error(conn, code)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  @doc """
  Verifies a user's email address.
  """
  @spec verify_email(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def verify_email(conn, attrs) do
    with :ok <- permit(:verify_email, conn.assigns, nil),
         {:ok, user} <- SignupGate.verify_email(attrs) do
      render(conn, :user, %{user: user})
    else
      {:error, code} when is_atom(code) ->
        handle_error(conn, code)

      {:error, %Changeset{} = changeset} ->
        handle_error(conn, :invalid_parameter, changeset)
    end
  end

  @spec permit(:create | :verify_email, map(), nil) :: :ok | {:error, any()}
  defp permit(action, params, user) do
    Bodyguard.permit(UserPolicy, action, params, user)
  end
end
