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

defmodule Utils.Helpers.CryptoTest do
  use ExUnit.Case, async: true
  alias Utils.Helpers.Crypto

  describe "generate_base64_key/1" do
    test "returns a key with the specified length" do
      key = Crypto.generate_base64_key(32)
      # ceil(32 * 4 / 3)
      assert String.length(key) == 43

      # Test with another length to make sure it's not hardcoded.
      key = Crypto.generate_base64_key(64)
      # ceil(64 * 4 / 3)
      assert String.length(key) == 86
    end
  end
end
