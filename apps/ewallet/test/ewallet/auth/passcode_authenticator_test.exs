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

defmodule EWallet.PassAuthenticatorTest do
  use EWallet.DBCase, async: true
  alias EWallet.PasscodeAuthenticator

  describe "create" do
    test "return {:ok, secret_2fa_code}" do
      assert {:ok, _} = PasscodeAuthenticator.create()
    end
  end

  describe "verify" do
    test "return :ok when the given passcode is correct" do
      assert {:ok, secret_2fa_key} = PasscodeAuthenticator.create()

      passcode = :pot.totp(secret_2fa_key)

      assert PasscodeAuthenticator.verify(passcode, secret_2fa_key) == :ok
    end

    test "return {:error, :invalid_passcode} when the given passcode is incorrect" do
      assert {:ok, secret_2fa_key} = PasscodeAuthenticator.create()

      assert PasscodeAuthenticator.verify("000000", secret_2fa_key) == {:error, :invalid_passcode}
      assert PasscodeAuthenticator.verify("", secret_2fa_key) == {:error, :invalid_passcode}
    end

    test "return {:error, :invalid_parameter} when given invalid parameters" do
      assert PasscodeAuthenticator.verify(1, 1) == {:error, :invalid_parameter}
      assert PasscodeAuthenticator.verify("1", false) == {:error, :invalid_parameter}
      assert PasscodeAuthenticator.verify("0", 1) == {:error, :invalid_parameter}
    end
  end
end
