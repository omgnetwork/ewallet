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

defmodule KeychainTest do
  use Keychain.DBCase

  describe "private_key_for_wallet/1" do
    test "returns the private key for the given wallet id"
  end

  describe "private_key_for_uuid/1" do
    test "returns the private key for the given wallet uuid"
  end

  describe "public_key_for_uuid/1" do
    test "returns the public key for the given wallet uuid"
  end

  describe "insert/1" do
    test "returns the keychain inserted with the given attributes"
  end
end
