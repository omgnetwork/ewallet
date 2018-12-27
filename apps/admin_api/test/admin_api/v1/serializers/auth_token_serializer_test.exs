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

defmodule AdminAPI.V1.AuthTokenSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias AdminAPI.V1.AuthTokenSerializer

  describe "AuthTokenSerializer.serialize/1" do
    test "data contains the session token" do
      auth_token = insert(:auth_token)
      serialized = AuthTokenSerializer.serialize(auth_token)

      assert serialized.object == "authentication_token"
      assert serialized.authentication_token == auth_token.token
      assert serialized.user_id == auth_token.user.id
      assert serialized.user != nil
    end
  end
end
