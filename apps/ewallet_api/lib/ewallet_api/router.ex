defmodule EWalletAPI.Router do
  use EWalletAPI, :router
  alias EWalletAPI.StatusController
  alias EWalletAPI.VersionedRouter

  get "/api/", StatusController, :status
  forward "/api/", VersionedRouter
end
