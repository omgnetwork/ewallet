defmodule AdminAPI.Router do
  use AdminAPI, :router
  use EWallet.Web.APIDocs, scope: "/api/admin"
  alias AdminAPI.{StatusController, VersionedRouter}

  scope "/api/admin" do
    get("/", StatusController, :status)
    forward("/", VersionedRouter)
  end
end
