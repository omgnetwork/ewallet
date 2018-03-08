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
    # ...
    scope "/scope" do
      get "/docs", EWallet.Web.APIDocs.Controller, :index, private: %{redirect_to: "/scope/docs.ui"}
      get "/docs.ui", EWallet.Web.APIDocs.Controller, :ui
      get "/docs.yaml", EWallet.Web.APIDocs.Controller, :yaml
    end
    # ...
  end
  ```

  """
  defmodule Controller do
    @moduledoc false
    use EWallet, :controller

    @doc false
    def index(%{private: %{redirect_to: destination}} = conn, _attrs) do
      redirect conn, to: destination
    end

    @doc false
    def ui(conn, _attrs) do
      ui_path = Path.join([Application.app_dir(:ewallet), "priv", "swagger.html"])
      send_file(conn, 200, ui_path)
    end

    @doc false
    def yaml(conn, _attrs) do
      otp_app   = endpoint_module(conn).config(:otp_app)
      spec_path = Path.join([Application.app_dir(otp_app), "priv", "spec.yaml"])
      send_file(conn, 200, spec_path)
    end
  end

  @doc false
  defmacro __using__(scope: api_scope) do
    quote do
      scope unquote(api_scope) do
        get "/docs", Controller, :index, private: %{redirect_to: unquote(api_scope) <> "/docs.ui"}
        get "/docs.ui", Controller, :ui
        get "/docs.yaml", Controller, :yaml
      end
    end
  end
end
