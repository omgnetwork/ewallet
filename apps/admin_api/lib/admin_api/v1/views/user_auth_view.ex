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

defmodule AdminAPI.V1.UserAuthView do
  use AdminAPI, :view
  alias EWallet.Web.V1.ResponseSerializer
  alias EWallet.Web.V1.UserAuthTokenSerializer

  def render("auth_token.json", %{auth_token: auth_token}) do
    auth_token
    |> UserAuthTokenSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("empty_response.json", _attrs) do
    %{}
    |> ResponseSerializer.serialize(success: true)
  end
end
