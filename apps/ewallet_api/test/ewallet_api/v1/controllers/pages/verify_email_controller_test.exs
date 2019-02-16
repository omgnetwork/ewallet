# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWalletAPI.V1.VerifyEmailControllerTest do
  use EWalletAPI.ConnCase, async: true
  alias EWalletDB.{Invite, User}
  alias ActivityLogger.System

  describe "verify/2" do
    defp verify_email(email, token) do
      build_conn()
      |> get("/pages/client/v1/verify_email?email=#{email}&token=#{token}")
    end

    test "redirects to the default success_url when invite.success_url is not given" do
      {:ok, user} = :standalone_user |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(user, %System{})

      conn = verify_email(user.email, invite.token)

      assert redirected_to(conn) == "/pages/client/v1/verify_email/success"
    end

    test "redirects to the invite.success_url on success" do
      {:ok, user} = :standalone_user |> params_for() |> User.insert()

      {:ok, invite} =
        Invite.generate(user, %System{}, success_url: "https://example.com/success_url")

      conn = verify_email(user.email, invite.token)

      assert redirected_to(conn) == "https://example.com/success_url"
    end

    test "returns an error when the email is invalid" do
      {:ok, user} = :standalone_user |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(user, %System{})

      conn = verify_email("wrong@example.com", invite.token)
      response = text_response(conn, :ok)

      assert response ==
               "We were unable to verify your email address. There is no pending email verification for the provided email and token."
    end

    test "returns an error when the token is invalid" do
      {:ok, user} = :standalone_user |> params_for() |> User.insert()
      {:ok, _invite} = Invite.generate(user, %System{})

      conn = verify_email(user.email, "wrong_token")
      response = text_response(conn, :ok)

      assert response ==
               "We were unable to verify your email address. There is no pending email verification for the provided email and token."
    end
  end

  describe "success/2" do
    test "returns the success text" do
      response =
        build_conn()
        |> get("/pages/client/v1/verify_email/success")
        |> text_response(:ok)

      assert response == "Your email address has been successfully verified!"
    end
  end
end
