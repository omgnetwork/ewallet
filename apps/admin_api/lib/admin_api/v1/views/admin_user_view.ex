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

defmodule AdminAPI.V1.AdminUserView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ResponseSerializer, AdminUserSerializer}

  def render("admin_user.json", %{admin_user: admin_user}) do
    admin_user
    |> AdminUserSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("admin_users.json", %{admin_users: admin_users}) do
    admin_users
    |> AdminUserSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("empty.json", %{success: success}) do
    ResponseSerializer.serialize(%{}, success: success)
  end
end
