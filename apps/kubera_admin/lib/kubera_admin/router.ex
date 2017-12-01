defmodule KuberaAdmin.Router do
  use KuberaAdmin, :router
  alias KuberaAdmin.StatusController
  alias KuberaAdmin.VersionedRouter

  get "/", StatusController, :status
  forward "/", VersionedRouter
end
