defmodule KuberaAPI.V1.Router do
  use KuberaAPI, :router
  alias KuberaAPI.V1.Plug.{ClientAuth, ProviderAuth}

  pipeline :provider_api do
    plug ProviderAuth
  end

  pipeline :client_api do
    plug ClientAuth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Provider endpoints
  scope "/", KuberaAPI.V1 do
    pipe_through [:api, :provider_api]

    post "/user.create", UserController, :create
    post "/user.get", UserController, :get
    post "/user.update", UserController, :update

    post "/user.list_balances", BalanceController, :all
    post "/user.credit_balance", BalanceController, :credit
    post "/user.debit_balance", BalanceController, :debit

    post "/login", AuthController, :login
  end

  # Client endpoints
  scope "/", KuberaAPI.V1 do
    pipe_through [:api, :client_api]

    post "/me.get", SelfController, :get
    post "/me.get_settings", SelfController, :get_settings

    post "/logout", AuthController, :logout
  end

  # Public endpoints
  scope "/", KuberaAPI.V1 do
    pipe_through [:api]

    post "/status", StatusController, :index
    post "/status.deps", StatusController, :status_deps
    post "/status.server_error", StatusController, :server_error

    match :*, "/*path", FallbackController, :not_found
  end
end
