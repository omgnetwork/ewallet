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

defmodule EWallet.EmailValidatorTest do
  use ExUnit.Case, async: true
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
