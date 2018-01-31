defmodule AdminAPI.Router do
  use AdminAPI, :router
  alias AdminAPI.StatusController
  alias AdminAPI.VersionedRouter

  get "/admin/api/", StatusController, :status
  forward "/admin/api/", VersionedRouter
end
