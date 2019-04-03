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

alias Utils.Helpers.Crypto

defmodule EWallet.PasscodeAuthenticator do
  @number_of_bytes 10

  def verify(passcode, secret) do
    if :pot.valid_totp(passcode, secret) do
      {:ok}
    else
      {:error, :invalid_passcode}
    end
  end

  def create do
    {:ok, Crypto.generate_base32_key(@number_of_bytes)}
  end
end
