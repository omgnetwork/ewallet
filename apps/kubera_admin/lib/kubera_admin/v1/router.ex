defmodule KuberaAdmin.V1.Router do
  use KuberaAdmin, :router
  alias KuberaAdmin.V1.{ClientAuthPlug, UserAuthPlug}

  # Pipeline for plugs to apply for all endpoints
  pipeline :api do
    plug :accepts, ["json"]
  end

  # Pipeline for endpoints that require client authentication
  pipeline :client_api do
    plug ClientAuthPlug
  end

  # Pipeline for endpoints that require user authentication
  pipeline :user_api do
    plug UserAuthPlug
  end

  # Authenticated endpoints
  scope "/", KuberaAdmin.V1 do
    pipe_through [:api, :user_api]

    # Account endpoints
    post "/account.all", AccountController, :all
    post "/account.get", AccountController, :get
    post "/account.create", AccountController, :create
    post "/account.update", AccountController, :update

    # Self endpoints (operations on the currently authenticated user)
    post "/me.get", SelfController, :get
    post "/logout", AuthController, :logout
  end

  # Public endpoints (still protected by API key)
  scope "/", KuberaAdmin.V1 do
    pipe_through [:api, :client_api]

    post "/login", AuthController, :login

    post "/status", StatusController, :index
    post "/status.server_error", StatusController, :server_error

    match :*, "/*path", FallbackController, :not_found
  end
end
