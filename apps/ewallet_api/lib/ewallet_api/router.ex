defmodule EWalletAPI.Router do
  use EWalletAPI, :router
  alias EWalletAPI.StatusController
  alias EWalletAPI.VersionedRouter

  get "/", StatusController, :status
  forward "/", VersionedRouter
end
