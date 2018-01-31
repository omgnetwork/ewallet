defmodule EWallet.EmailValidatorTest do
  use ExUnit.Case
  alias EWallet.EmailValidator

  describe "EWallet.EmailValidator.is_valid_email?/1" do
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
    end
  end
end
