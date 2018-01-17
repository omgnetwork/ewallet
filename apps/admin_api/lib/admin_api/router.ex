defmodule AdminAPI.Router do
  use AdminAPI, :router
  alias AdminAPI.StatusController
  alias AdminAPI.VersionedRouter

  get "/", StatusController, :status
  forward "/", VersionedRouter
end
