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

defmodule AdminAPI.UpdateEmailAddressEmailTest do
  use AdminAPI.ConnCase, async: true
  alias AdminAPI.UpdateEmailAddressEmail
  alias EWalletDB.UpdateEmailRequest

  defp create_email(email_address, token) do
    user = insert(:user)

    _request =
      insert(:update_email_request, email: email_address, token: token, user_uuid: user.uuid)

    request = UpdateEmailRequest.get(email_address, token)

    email =
      UpdateEmailAddressEmail.create(request, "https://reset_url/?email={email}&token={token}")

    email
  end

  describe "ForgetPasswordEmail.create/2" do
    test "creates an email with correct from and to addresses" do
      email = create_email("test_update_email@example.com", "the_token")

      # `from` should be the one set in the config
      assert email.from == Application.get_env(:ewallet, :sender_email)

      # `to` should be the user's new email
      assert email.to == "test_update_email@example.com"
    end

    test "creates an email with non-empty subject" do
      email = create_email("test_update_email@example.com", "the_token")
      assert String.length(email.subject) > 0
    end

    test "creates an email with email and token in the html body" do
      email = create_email("test_update_email@example.com", "the_token")

      assert email.html_body =~
               "https://reset_url/?email=test_update_email%40example.com&token=the_token"
    end

    test "creates an email with email and token in the text body" do
      email = create_email("test_update_email@example.com", "the_token")

      assert email.text_body =~
               "https://reset_url/?email=test_update_email%40example.com&token=the_token"
    end

    test "creates an email with properly encoded plus sign" do
      email = create_email("test_update_email+test@example.com", "the_token")

      assert email.html_body =~
               "https://reset_url/?email=test_update_email%2Btest%40example.com&token=the_token"
    end
  end
end
