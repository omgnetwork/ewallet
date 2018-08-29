defmodule EWalletAPI.Router do
  use EWalletAPI, :router
  use EWallet.Web.APIDocs, scope: "/api/client"
  alias EWalletAPI.{StatusController, VersionedRouter}
  alias EWalletAPI.V1.PageRouter

  scope "/pages/client/v1" do
    forward("/", PageRouter)
  end

  scope "/api/client" do
    get("/", StatusController, :status)
    forward("/", VersionedRouter)
  end
end
