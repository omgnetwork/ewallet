defmodule KuberaAPI.Router do
  use KuberaAPI, :router
  alias KuberaAPI.StatusController
  alias KuberaAPI.VersionedRouter

  get "/", StatusController, :status
  forward "/", VersionedRouter
end
