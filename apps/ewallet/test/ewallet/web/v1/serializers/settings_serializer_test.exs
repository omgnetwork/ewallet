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

defmodule EWallet.Web.V1.SettingsSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Web.V1.SettingsSerializer

  describe "V1.SettingsSerializer" do
    test "serialized data contains a list of tokens" do
      settings = %{tokens: build_list(3, :token)}
      serialized = SettingsSerializer.serialize(settings)

      assert serialized.object == "setting"
      assert Map.has_key?(serialized, :tokens)
      assert is_list(serialized.tokens)
      assert length(serialized.tokens) == 3
    end
  end
end
