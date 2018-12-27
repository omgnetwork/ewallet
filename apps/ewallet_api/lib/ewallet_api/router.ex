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

defmodule EWalletAPI.Router do
  use EWalletAPI, :router
  use EWallet.Web.APIDocs, scope: "/api/client"
  alias EWalletAPI.{StatusController, V1.PageRouter, VersionedRouter}

  scope "/pages/client/v1" do
    forward("/", PageRouter)
  end

  scope "/api/client" do
    get("/", StatusController, :status)
    forward("/", VersionedRouter)
  end
end
