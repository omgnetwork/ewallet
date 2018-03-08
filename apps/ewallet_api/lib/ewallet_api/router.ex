defmodule EWalletAPI.Router do
  use EWalletAPI, :router
  use EWallet.Web.APIDocs, scope: "/api"
  alias EWalletAPI.{StatusController, VersionedRouter}

  scope "/api" do
    get "/", StatusController, :status
    forward "/", VersionedRouter
  end
end
