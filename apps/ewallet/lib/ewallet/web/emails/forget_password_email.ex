# Copyright 2018 OmiseGO Pte Ltd
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

  def create(request, redirect_url) do
    sender = Application.get_env(:ewallet, :sender_email)

    link =
      redirect_url
      |> String.replace("{email}", URI.encode_www_form(request.user.email))
      |> String.replace("{token}", request.token)

    new_email()
    |> to(request.user.email)
    |> from(sender)
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
