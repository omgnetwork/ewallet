defmodule KuberaAPI.V1.Router do
  use KuberaAPI, :router
  alias KuberaAPI.V1.Plug.ProviderAuth

  pipeline :provider_api do
    plug :accepts, ["json"]
    plug ProviderAuth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", KuberaAPI.V1 do
    pipe_through :provider_api

    post "/user.create", UserController, :create
    post "/user.get", UserController, :get
  end

  scope "/", KuberaAPI.V1 do
    pipe_through :api

    post "/status", StatusController, :index
    post "/status.deps", StatusController, :status_deps
    post "/status.server_error", StatusController, :server_error

    match :*, "/*path", FallbackController, :not_found
  end
end
