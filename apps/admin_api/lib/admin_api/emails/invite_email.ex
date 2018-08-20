defmodule AdminAPI.InviteEmail do
  @moduledoc """
  The module that generates invite email templates.
  """
  import Bamboo.Email

  def create(invite, redirect_url) do
    sender = Application.get_env(:ewallet, :sender_email)

    link =
      redirect_url
      |> String.replace("{email}", URI.encode_www_form(invite.user.email))
      |> String.replace("{token}", invite.token)

    new_email()
    |> to(invite.user.email)
    |> from(sender)
    |> subject("eWallet: Invitation")
    |> html_body(html(link))
    |> text_body(text(link))
  end

  defp html(link) do
    """
    <p>You have been invited to join the eWallet.</p>

    <p>
      <strong>Click the link to complete the email verification: </strong>
      <a href="#{link}">#{link}</a>
    </p>
    """
  end

  defp text(link) do
    """
    You have been invited to join the eWallet.

    Copy & paste the link into your browser to accept the invite: #{link}
    """
  end
end
