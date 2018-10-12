defmodule EWalletAPI.V1.VerifyEmailController do
  @moduledoc """
  Handles pages for email verification.
  """
  use EWalletAPI, :controller
  import EWalletAPI.V1.PageRouter.Helpers, only: [verify_email_path: 2]
  alias EWallet.SignupGate
  alias EWallet.Web.V1.ErrorHandler
  alias EWalletDB.Setting

  def verify_url, do: build_url("/pages/client/v1/verify_email?email={email}&token={token}")

  def success_url, do: build_url("/pages/client/v1/verify_email/success")

  defp build_url(path) do
    Setting.get_value("base_url") <> path
  end

  @doc """
  Renders the landing page to start the email verification steps.
  """
  def verify(conn, attrs) do
    case SignupGate.verify_email(attrs) do
      {:ok, %{success_url: nil}} ->
        redirect(conn, to: verify_email_path(conn, :success))

      {:ok, %{success_url: success_url}} ->
        redirect(conn, external: success_url)

      {:error, error} ->
        case Map.get(ErrorHandler.errors(), error) do
          %{description: description} ->
            text(conn, "We were unable to verify your email address. " <> description)

          nil ->
            text(conn, "We were unable to verify your email address. An unknown error occured.")
        end
    end
  end

  @doc """
  Renders the page to show when email verification is successful.
  """
  def success(conn, _attrs) do
    text(conn, "Your email address has been successfully verified!")
  end
end
