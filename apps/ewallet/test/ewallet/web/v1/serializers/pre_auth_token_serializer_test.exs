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

defmodule EWallet.Web.V1.PreAuthTokenSerializerTest do
  use EWallet.Web.SerializerCase, :v1

  alias EWallet.Web.V1.PreAuthTokenSerializer

  describe "PreAuthTokenSerializer.serialize/1" do
    test "return correct pre authentication token" do
      pre_auth_token = insert(:pre_auth_token)
      serialized = PreAuthTokenSerializer.serialize(pre_auth_token)

      assert serialized.object == "pre_authentication_token"
      assert serialized.pre_authentication_token == pre_auth_token.token
      assert serialized.user_id == pre_auth_token.user.id
      assert serialized.user != nil
    end
  end
end
