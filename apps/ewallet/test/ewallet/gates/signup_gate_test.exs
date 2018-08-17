defmodule EWallet.SignupGateTest do
  use EWallet.DBCase, async: true

  describe "signup/1" do
    test "returns the invite when the signup is successful"
    test "returns the invite when the signup is successful and optional passwords provided"
    test "returns the invite when provided with an email that has not been verified"
    test "returns an error when attempting to signup with an email that is already verified"
    test "returns an error when the email format is invalid"
    test "returns an error when the passwords were provided but do not match"
    test "returns an error when the passwords are less than 8 characters"
    test "returns an error when the redirect_url is not provided"
  end

  describe "verify_email/1" do
    test "returns the user when the verification is successful"
    test "returns the user when the verification is successful and new passwords provided"
    test "returns an error when the email format is invalid"
    test "returns an error when the token is not provided"
    test "returns an error when the email and token do not match an existing invite"
    test "returns an error when the passwords do not match"
    test "returns an error when the passwords are less than 8 characters"
    test "returns an error when the passwords were not set before and are not provided"
  end
end
