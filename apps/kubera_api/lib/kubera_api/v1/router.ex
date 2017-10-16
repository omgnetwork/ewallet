defmodule KuberaAPI.V1.Router do
  use KuberaAPI, :router

  scope "/", KuberaAPI.V1 do
    post "/user.get", UserController, :get
    post "/user.create", UserController, :create

    post "/status", StatusController, :index
  end
end
