defmodule EWalletAPI.Router do
  use EWalletAPI, :router
  use EWallet.Web.APIDocs, scope: "/api/client"
  alias EWalletAPI.{StatusController, VersionedRouter}

  scope "/api/client" do
    get("/", StatusController, :status)
    forward("/", VersionedRouter)
  end
end
