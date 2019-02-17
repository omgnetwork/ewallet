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

defmodule EWallet.Web.APIDocs do
  @moduledoc """
  This module generates controller actions for serving API docs.

  To use this module, simply add `use EWallet.Web.APIDocs, scope: "/the_scope"` to your router.
  It will automatically add 3 controller actions for displaying API docs, with paths being
  relative to the given scope.

  1. `/docs` - Redirects to `/docs.ui`.
  2. `/docs.ui` - Serves the Swagger UI page, this page allows developers to browse the API docs
    in a visual and interactive way.
  3. `/docs.yaml` - Serves the actual API spec in yaml format.

  ## Examples
  ```
  defmodule SomeApp.Router do
    # ...
    use EWallet.Web.APIDocs, scope: "/scope"
    # ...
  end
  ```

  The code above is equivalent to:

  ```
  defmodule SomeApp.Router do
    scope "/scope" do
      get "/docs", EWallet.Web.APIDocs.Controller, :index, private: %{redirect_to: "/scope/docs.ui"}
      # ...

      get "/errors", Controller, :forward, private: %{redirect_to: api_scope <> "/errors.ui"}
      # ...
    end
  end
  ```

  The endpoints are then accessible at `/scope/docs`, `/scope/errors`, etc.
  """
  alias EWallet.Web.APIDocs.Controller

  @doc false
  defmacro __using__(scope: api_scope) do
    quote bind_quoted: binding() do
      scope api_scope do
        get("/docs", Controller, :forward, private: %{redirect_to: api_scope <> "/docs.ui"})
        get("/docs.ui", Controller, :ui)
        get("/docs.yaml", Controller, :yaml)
        get("/docs.json", Controller, :json)

        get("/errors", Controller, :forward, private: %{redirect_to: api_scope <> "/errors.ui"})
        get("/errors.ui", Controller, :errors_ui)
        get("/errors.yaml", Controller, :errors_yaml)
        get("/errors.json", Controller, :errors_json)
      end
    end
  end
end
