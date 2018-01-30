defmodule AdminAPI.V1.Router do
  use AdminAPI, :router
  alias AdminAPI.V1.{ClientAuthPlug, UserAuthPlug}

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
  scope "/", AdminAPI.V1 do
    pipe_through [:api, :user_api]

    # Minted Token endpoints
    post "/minted_token.all", MintedTokenController, :all
    post "/minted_token.get", MintedTokenController, :get

    post "/transaction.all", TransactionController, :all
    post "/transaction.get", TransactionController, :get

    # Account endpoints
    post "/account.all", AccountController, :all
    post "/account.get", AccountController, :get
    post "/account.create", AccountController, :create
    post "/account.update", AccountController, :update
    post "/account.list_users", AccountController, :list_users
    post "/account.assign_user", AccountController, :assign_user
    post "/account.unassign_user", AccountController, :unassign_user
    post "/account.upload_avatar", AccountController, :upload_avatar

    # User endpoints
    post "/user.all", UserController, :all
    post "/user.get", UserController, :get

    # Admin endpoints
    post "/admin.all", AdminController, :all
    post "/admin.get", AdminController, :get
    post "/admin.upload_avatar", AdminController, :upload_avatar

    # Self endpoints (operations on the currently authenticated user)
    post "/me.get", SelfController, :get
    post "/me.get_account", SelfController, :get_account
    post "/me.get_accounts", SelfController, :get_accounts
    post "/logout", AuthController, :logout
  end

  # Public endpoints (still protected by API key)
  scope "/", AdminAPI.V1 do
    pipe_through [:api, :client_api]

    post "/login", AuthController, :login

    post "/status", StatusController, :index
    post "/status.server_error", StatusController, :server_error
  end

  # Fallback endpoints. Handles all remaining routes
  # that are not handled by the scopes above.
  scope "/", AdminAPI.V1 do
    pipe_through [:api]
    match :*, "/*path", FallbackController, :not_found
  end
end
