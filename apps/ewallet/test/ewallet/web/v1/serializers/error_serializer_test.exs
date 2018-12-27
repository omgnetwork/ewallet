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

defmodule EWallet.Web.V1.ErrorSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Web.V1.ErrorSerializer

  describe "V1.ErrorSerializer.serialize" do
    test "data contains the code, description and messages" do
      code = "error_code"
      description = "This is the description"
      messages = %{field: "required"}
      serialized = ErrorSerializer.serialize(code, description, messages)

      assert serialized.object == "error"
      assert serialized.code == "error_code"
      assert serialized.description == "This is the description"
      assert serialized.messages == %{field: "required"}
    end
  end
end
