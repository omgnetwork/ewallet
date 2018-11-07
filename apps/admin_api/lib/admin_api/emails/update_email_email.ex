defmodule AdminAPI.UpdateEmailEmail do
  @moduledoc """
  The module that generates the email template for updating the email.
  """
  import Bamboo.Email

  def create(request, redirect_url) do
    sender = Application.get_env(:ewallet, :sender_email)

    link =
      redirect_url
      |> String.replace("{email}", URI.encode_www_form(request.email))
      |> String.replace("{token}", request.token)

    new_email()
    |> to(request.email)
    |> from(sender)
    |> subject("OmiseGO eWallet: Update Email Request")
    |> html_body(html(link))
    |> text_body(text(link))
  end

  defp html(link) do
    """
    Hello!<br/>
    <br/>
    A request to update your email address has been received. To update your email,
    click on the link below:<br/>
    <br/>
    <a href="#{link}">#{link}</a><br/>
    <br/>
    If you did not request an email update, you can discard this email.<br/>
    <br/>
    OmiseGO eWallet
    """
  end

  defp text(link) do
    """
    Hello!

    A request to update your email address has been received. To update your email,
    copy & paste the link into your browser:

    #{link}

    If you did not request an email update, you can discard this email.

    OmiseGO eWallet
    """
  end
end
