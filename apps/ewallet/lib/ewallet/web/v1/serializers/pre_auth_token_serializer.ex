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

defmodule EWallet.Web.V1.PreAuthTokenSerializer do
  @moduledoc """
  Serializes pre authentication token data into V1 response format.
  """
  alias EWallet.Web.V1.UserSerializer
  alias Utils.Helpers.Assoc
  alias EWalletDB.{PreAuthToken}

  def serialize(%PreAuthToken{} = auth_token) do
    %{
      object: "pre_authentication_token",
      pre_authentication_token: auth_token.token,
      user_id: Assoc.get(auth_token, [:user, :id]),
      user: UserSerializer.serialize(auth_token.user),
      account_id: nil,
      account: nil,
      master_admin: nil,
      role: nil,
      global_role: Assoc.get(auth_token, [:user, :global_role])
    }
  end
end
