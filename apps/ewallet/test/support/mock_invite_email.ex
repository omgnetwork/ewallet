defmodule EWallet.Web.MockInviteEmail do
  @moduledoc """
  A module that mocks the email template for user invitation.
  """
  import Bamboo.Email

  def create(_invite, _redirect_url) do
    new_email()
    |> to("to_user@example.com")
    |> from("test_sender@example.com")
    |> subject("eWallet: Invitation")
    |> html_body(html())
    |> text_body(text())
  end

  defp html do
    """
    <p>HTML content for MockInviteEmail</p>
    """
  end

  defp text do
    """
    Text content for MockInviteEmail
    """
  end
end
