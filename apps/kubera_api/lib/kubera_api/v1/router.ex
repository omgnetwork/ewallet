defmodule KuberaAPI.V1.Router do
  use KuberaAPI, :router
  alias KuberaAPI.V1.Plug.{ClientAuth, ProviderAuth, Idempotency}

  pipeline :provider_api do
    plug ProviderAuth
  end

  pipeline :client_api do
    plug ClientAuth
  end

  pipeline :idempotency do
    plug Idempotency
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

    # Idempotent requests
    scope "/" do
      pipe_through [:idempotency]

      post "/user.credit_balance", TransactionController, :credit
      post "/user.debit_balance", TransactionController, :debit
    end

    post "/login", AuthController, :login
    post "/get_settings", SettingsController, :get_settings
  end

  # Client endpoints
  scope "/", KuberaAPI.V1 do
    pipe_through [:api, :client_api]

    post "/me.get", SelfController, :get
    post "/me.get_settings", SelfController, :get_settings
    post "/me.list_balances", SelfController, :get_balances

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
