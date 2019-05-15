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

defmodule Frontend.Router do
  use Frontend, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:put_secure_browser_headers)
  end

  scope "/admin", Frontend do
    pipe_through(:browser)
    # All requests serve from the same index page
    match(:*, "/*path", PageController, :index)
  end

  scope "/client", Frontend do
    pipe_through(:browser)
    # All requests serve from the same index page
    match(:*, "/*path", PageController, :index)
  end
end
