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

defmodule EWallet.VerificationEmail do
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
      |> String.replace("{email}", URI.encode_www_form(invite.user.email))
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
