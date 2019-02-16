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

defmodule EWalletAPI.V1.PageRouter do
  @moduledoc """
  Routes for html pages.
  """
  use EWalletAPI, :router
  alias EWalletAPI.V1.StandalonePlug

  pipeline :pages do
    plug(:accepts, ["html"])
    plug(:put_layout, {EWalletAPI.V1.LayoutView, :layout})
  end

  pipeline :standalone do
    plug(StandalonePlug)
  end

  # Pages for standalone functionalities
  scope "/", EWalletAPI.V1 do
    pipe_through([:pages, :standalone])

    get("/verify_email", VerifyEmailController, :verify)
    get("/verify_email/success", VerifyEmailController, :success)
  end
end
