defmodule EWalletAPI.VerificationEmail do
  @moduledoc """
  The module that generates invite email templates.
  """
  import Bamboo.Email
  alias EWallet.Web.Preloader

  def create(invite, redirect_url) do
    sender = Application.get_env(:ewallet, :sender_email)
    {:ok, invite} = Preloader.preload_one(invite, [:user])

    link =
      redirect_url
      |> String.replace("{email}", invite.user.email)
      |> String.replace("{token}", invite.token)

    new_email()
    |> to(invite.user.email)
    |> from(sender)
    |> subject("OmiseGO eWallet: Verify your email")
    |> html_body(html(link))
    |> text_body(text(link))
  end

  defp html(link) do
    """
    <p>
      <strong>Click the link to complete the email verification process: </strong>
      <a href="#{link}">#{link}</a>
    </p>
    """
  end

  defp text(link) do
    """
    Copy & paste the link into your browser to complete the email verification process: #{link}
    """
  end
end
