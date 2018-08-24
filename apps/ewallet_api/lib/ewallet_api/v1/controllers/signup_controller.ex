defmodule EWalletAPI.V1.SignupController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.{SignupGate, UserPolicy}
  alias EWallet.Web.Preloader
  alias EWalletAPI.V1.VerifyEmailController
  alias EWalletAPI.VerificationEmail

  @doc """
  Signs up a new user.

  This function is used when the eWallet is setup as a standalone solution,
  allowing users to sign up without an integration with the provider's server.
  """
  @spec signup(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def signup(conn, attrs) do
    with :ok <- permit(:create, conn.assigns, nil),
         attrs <- Map.put_new(attrs, "verification_url", VerifyEmailController.verify_url()),
         attrs <- Map.put_new(attrs, "success_url", VerifyEmailController.success_url()),
         {:ok, _invite} <- SignupGate.signup(attrs, &VerificationEmail.create/2) do
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
         {:ok, invite} <- SignupGate.verify_email(attrs),
         {:ok, invite} <- Preloader.preload_one(invite, :user) do
      render(conn, :user, %{user: invite.user})
    else
      {:error, code} ->
        handle_error(conn, code)

      {:error, code, description} ->
        handle_error(conn, code, description)
    end
  end

  @spec permit(:create | :verify_email, map(), nil) :: :ok | {:error, any()}
  defp permit(action, params, user) do
    Bodyguard.permit(UserPolicy, action, params, user)
  end
end
