defmodule AdminAPI.InviteEmail do
  @moduledoc """
  The module that generates invite email templates.
  """
  import Bamboo.Email
  import Bamboo.Phoenix
  import AdminAPI.Endpoint, only: [path: 1]

  def create(invite) do
    config = Application.get_env(:admin_api, :email)
    email  = invite.user.email
    token  = invite.token
    link   = path("/invite_accept/#{email}/#{token}")

    new_email()
    |> to(invite.user.email)
    |> from(config[:sender])
    |> subject("You are invited")
    |> html_body("""
       <strong>Click the link to accept the invite: </strong>
       <a href="#{link}">#{link}</a>
       """)
    |> text_body("""
       Copy & paste the link into your browser to accept the invite: #{link}
       """)
  end

  # defp base_email do
  #   new_email
  #   |> from("myapp@example.com")
  #   |> put_html_layout({MyApp.LayoutView, "email.html"})
  #   |> put_text_layout({MyApp.LayoutView, "email.text"})
  # end
end
