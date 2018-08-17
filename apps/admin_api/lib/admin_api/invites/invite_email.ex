defmodule AdminAPI.InviteEmail do
  @moduledoc """
  The module that generates invite email templates.
  """
  import Bamboo.Email

  def create(invite, redirect_url) do
    sender = Application.get_env(:admin_api, :sender_email)

    link =
      redirect_url
      |> String.replace("{email}", URI.encode_www_form(invite.user.email))
      |> String.replace("{token}", invite.token)

    new_email()
    |> to(invite.user.email)
    |> from(sender)
    |> subject("OmiseGO eWallet: Invitation")
    |> html_body(html(link))
    |> text_body(text(link))
  end

  defp html(link) do
    """
    <strong>Click the link to accept the invite: </strong>
    <a href="#{link}">#{link}</a>
    """
  end

  defp text(link) do
    """
    Copy & paste the link into your browser to accept the invite: #{link}
    """
  end
end
