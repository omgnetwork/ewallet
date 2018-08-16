defmodule EWallet.EmailValidatorTest do
  use ExUnit.Case
  alias EWallet.EmailValidator

  describe "valid?/1" do
    test "returns true on valid emails" do
      assert EmailValidator.valid?("johndoe@example.com")
      assert EmailValidator.valid?("john+doe@example.com")
      assert EmailValidator.valid?("john.doe+doe@example.com")
      assert EmailValidator.valid?("johndoe@example")
    end

    test "returns false on invalid emails" do
      refute EmailValidator.valid?("johndoe@example@example.com")
      refute EmailValidator.valid?("johndoe")
      refute EmailValidator.valid?("john@")
      refute EmailValidator.valid?("@example.com")
      refute EmailValidator.valid?(nil)
    end
  end

  describe "validate/1" do
    test "returns {:ok, email} on valid emails" do
      assert EmailValidator.validate("johndoe@example.com") == {:ok, "johndoe@example.com"}
      assert EmailValidator.validate("john+doe@example.com") == {:ok, "john+doe@example.com"}
      assert EmailValidator.validate("john.doe+d@example.com") == {:ok, "john.doe+d@example.com"}
      assert EmailValidator.validate("johndoe@example") == {:ok, "johndoe@example"}
    end

    test "returns {:error, :invalid_email} on invalid emails" do
      assert EmailValidator.validate("johndoe@example@example.com") == {:error, :invalid_email}
      assert EmailValidator.validate("johndoe") == {:error, :invalid_email}
      assert EmailValidator.validate("john@") == {:error, :invalid_email}
      assert EmailValidator.validate("@example.com") == {:error, :invalid_email}
      assert EmailValidator.validate(nil) == {:error, :invalid_email}
    end
  end
end
