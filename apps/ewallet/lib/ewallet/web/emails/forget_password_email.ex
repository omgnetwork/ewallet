# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWallet.ForgetPasswordEmail do
  @moduledoc """
  The module that generates password reset email templates.
  """
  import Bamboo.Email

  def create(request, reset_password_url, forward_url \\ nil) do
    sender = Application.get_env(:ewallet, :sender_email)

    link =
      reset_password_url
      |> replace_placeholders(request, true)
      |> append_forward_url(forward_url, request)

    new_email()
    |> to(request.user.email)
    |> from(sender)
    |> subject("OmiseGO eWallet: Password Reset Request")
    |> html_body(html(link))
    |> text_body(text(link))
  end

  defp append_forward_url(reset_password_url, forward_url, request)
       when not is_nil(forward_url) do
    # We need to replace {email} and {token} first without encoding them
    # as they will be encoded after along with the whole forward_url
    forward_url = replace_placeholders(forward_url, request, false)
    forward_url = URI.encode_query(%{"forward_url" => forward_url})

    Enum.join([reset_password_url, forward_url], "&")
  end

  defp append_forward_url(reset_password_url, _, _), do: reset_password_url

  defp replace_placeholders(url, request, encode) do
    email =
      case encode do
        true -> URI.encode_www_form(request.user.email)
        _ -> request.user.email
      end

    url
    |> String.replace("{email}", email)
    |> String.replace("{token}", request.token)
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
