defmodule AdminAPI.InviteEmail do
  @moduledoc """
  The module that generates invite email templates.
  """
  import Bamboo.Email
  import Bamboo.Phoenix

  def create(invite, redirect_url) do
    config = Application.get_env(:admin_api, :email)
    link   =
      redirect_url
      |> String.replace("{email}", invite.user.email)
      |> String.replace("{token}", invite.token)

    new_email()
    |> to(invite.user.email)
    |> from(config[:sender])
    |> subject("OmiseGO eWallet: Invitation")
    |> html_body(link)
    |> text_body(link)
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
