defmodule EWalletAdmin.Router do
  use EWalletAdmin, :router
  alias EWalletAdmin.StatusController
  alias EWalletAdmin.VersionedRouter

  get "/", StatusController, :status
  forward "/", VersionedRouter
end
