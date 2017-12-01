defmodule KuberaAdmin.V1.Router do
  use KuberaAdmin, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Authenticated endpoints
  scope "/", KuberaAdmin.V1 do
    pipe_through [:api]
  end

  # Public endpoints
  scope "/", KuberaAdmin.V1 do
    pipe_through [:api]

    post "/status", StatusController, :index
    post "/status.server_error", StatusController, :server_error

    match :*, "/*path", FallbackController, :not_found
  end
end
