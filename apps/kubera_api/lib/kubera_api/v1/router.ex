defmodule KuberaAPI.V1.Router do
  use KuberaAPI, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", KuberaAPI.V1 do
    pipe_through :api

    post "/user.get", UserController, :get
    post "/user.create", UserController, :create

    post "/status", StatusController, :index
    post "/status.server_error", StatusController, :server_error

    match :*, "/*path", FallbackController, :not_found
  end
end
