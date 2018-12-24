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

defmodule EWallet.SignupGateTest do
  use EWallet.DBCase, async: true
  alias EWallet.SignupGate
  alias EWallet.VerificationEmail
  alias EWalletDB.{Invite, User}
  alias ActivityLogger.System

  @verification_url "http://localhost:4000/verification_url?email={email}&token={token}"
  @success_url "http://localhost:4000/success_url"

  describe "signup/1" do
    test "returns the invite when signup with minimum inputs" do
      # Inserts the master account
      _ = insert(:account)

      {res, invite} =
        SignupGate.signup(
          %{
            "email" => "signup_success@example.com",
            "password" => "password",
            "password_confirmation" => "password",
            "verification_url" => @verification_url,
            "success_url" => @success_url
          },
          &VerificationEmail.create/2
        )

      assert res == :ok
      assert %Invite{} = invite
    end

    test "returns an error when the given verification_url is not whitelisted" do
      {res, code, meta} =
        SignupGate.signup(
          %{
            "email" => "with_verification_url@example.com",
            "password" => "password",
            "password_confirmation" => "password",
            "verification_url" => "https://example.com/verify",
            "success_url" => @success_url
          },
          &VerificationEmail.create/2
        )

      assert res == :error
      assert code == :prohibited_url
      assert meta == [param_name: "verification_url", url: "https://example.com/verify"]
    end

    test "returns an error when the given success_url is not whitelisted" do
      {res, code, meta} =
        SignupGate.signup(
          %{
            "email" => "with_verification_url@example.com",
            "password" => "password",
            "password_confirmation" => "password",
            "verification_url" => @verification_url,
            "success_url" => "https://example.com/verify_success"
          },
          &VerificationEmail.create/2
        )

      assert res == :error
      assert code == :prohibited_url
      assert meta == [param_name: "success_url", url: "https://example.com/verify_success"]
    end

    test "returns an error when the email format is invalid" do
      {res, code} =
        SignupGate.signup(
          %{
            "email" => "invalid-email-format",
            "password" => "password",
            "password_confirmation" => "password",
            "verification_url" => @verification_url,
            "success_url" => @success_url
          },
          &VerificationEmail.create/2
        )

      assert res == :error
      assert code == :invalid_email
    end

    test "returns an error when the password is not provided" do
      {res, code, description} =
        SignupGate.signup(
          %{
            "email" => "password_not_provided@example.com",
            "password" => "",
            "password_confirmation" => "",
            "verification_url" => @verification_url,
            "success_url" => @success_url
          },
          &VerificationEmail.create/2
        )

      assert res == :error
      assert code == :password_too_short
      assert description == [min_length: 8]
    end

    test "returns an error when the passwords were provided but do not match" do
      {res, code} =
        SignupGate.signup(
          %{
            "email" => "passwords_mismatch@example.com",
            "password" => "password",
            "password_confirmation" => "another_password",
            "verification_url" => @verification_url,
            "success_url" => @success_url
          },
          &VerificationEmail.create/2
        )

      assert res == :error
      assert code == :passwords_mismatch
    end

    test "returns an error when the passwords are less than 8 characters" do
      {res, code, description} =
        SignupGate.signup(
          %{
            "email" => "password_too_short@example.com",
            "password" => "pwd",
            "password_confirmation" => "pwd",
            "verification_url" => @verification_url,
            "success_url" => @success_url
          },
          &VerificationEmail.create/2
        )

      assert res == :error
      assert code == :password_too_short
      assert description == [min_length: 8]
    end
  end

  describe "verify_email/1" do
    test "returns the invite when the verification is successful" do
      {:ok, user} = :standalone_user |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(user, %System{})

      {res, invite} =
        SignupGate.verify_email(%{
          "email" => user.email,
          "token" => invite.token
        })

      assert res == :ok
      assert %Invite{} = invite
    end

    test "returns an error when the email format is invalid" do
      {:ok, user} = :standalone_user |> params_for() |> User.insert()
      {:ok, invite} = Invite.generate(user, %System{})

      {res, code} =
        SignupGate.verify_email(%{
          "email" => "not-an-email",
          "token" => invite.token
        })

      assert res == :error
      assert code == :invalid_email
    end

    test "returns :missing_token error when the token is not provided" do
      {:ok, user} = :standalone_user |> params_for() |> User.insert()
      {:ok, _invite} = Invite.generate(user, %System{})

      {res, code} =
        SignupGate.verify_email(%{
          "email" => user.email
        })

      assert res == :error
      assert code == :missing_token
    end

    test "returns :email_token_not_found error when the email and token do not match" do
      {:ok, user} = :standalone_user |> params_for() |> User.insert()
      {:ok, _invite} = Invite.generate(user, %System{})

      {res, code} =
        SignupGate.verify_email(%{
          "email" => user.email,
          "token" => "incorrect_token"
        })

      assert res == :error
      assert code == :email_token_not_found
    end
  end
end
