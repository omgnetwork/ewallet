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

defmodule EWallet.VerificationEmailTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.VerificationEmail
  alias EWalletDB.{Invite, User}
  alias ActivityLogger.System

  defp create_email(email) do
    {:ok, user} = :standalone_user |> params_for(email: email) |> User.insert()
    {:ok, invite} = Invite.generate(user, %System{})

    {VerificationEmail.create(invite, "https://invite_url/?email={email}&token={token}"),
     invite.token}
  end

  describe "create/2" do
    test "creates an email with correct from and to addresses" do
      {email, _token} = create_email("test@example.com")

      # `from` should be the one set in the config
      assert email.from == Application.get_env(:ewallet, :sender_email)

      # `to` should be the user's email
      assert email.to == "test@example.com"
    end

    test "creates an email with non-empty subject" do
      {email, _token} = create_email("test@example.com")
      assert String.length(email.subject) > 0
    end

    test "creates an email with email and token in the html body" do
      {email, token} = create_email("test@example.com")
      assert email.html_body =~ "https://invite_url/?email=test%40example.com&token=#{token}"
    end

    test "creates an email with email and token in the text body" do
      {email, token} = create_email("test@example.com")
      assert email.text_body =~ "https://invite_url/?email=test%40example.com&token=#{token}"
    end

    test "creates an email with properly encoded plus sign" do
      {email, token} = create_email("verification+test@example.com")

      assert email.html_body =~
               "https://invite_url/?email=verification%2Btest%40example.com&token=#{token}"
    end
  end
end
