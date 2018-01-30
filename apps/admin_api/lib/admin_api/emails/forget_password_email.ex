defmodule AdminAPI.ForgetPasswordEmail do
  @moduledoc """
  The module that generates password reset email templates.
  """
  import Bamboo.Email

  def create(request, redirect_url) do
    config = Application.get_env(:admin_api, :email)
    email  = request.user.email
    token  = request.token
    link   =
      redirect_url
      |> String.replace("{email}", email)
      |> String.replace("{token}", token)

    new_email()
    |> to(email)
    |> from(config[:sender])
    |> subject("OmiseGO eWallet: Password Reset Request")
    |> html_body(html(link))
    |> text_body(text(link))
  end

  defp html(link) do
    """
    Hello!
    <br/>
    A password reset request has been received. To update your password,
    click on the link below:
    <a href="#{link}">#{link}</a>
    <br/>
    If you did not request a password reset, you can discard this email.
    <br/>
    OmiseGO eWallet
    """
  end

  defp text(link) do
    """
    Copy & paste the link into your browser to reset your pasword: #{link}
    """
  end
end
