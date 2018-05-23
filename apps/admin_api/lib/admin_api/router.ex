defmodule AdminAPI.Router do
  use AdminAPI, :router
  use EWallet.Web.APIDocs, scope: "/admin/api"
  alias AdminAPI.{StatusController, VersionedRouter}

  scope "/admin/api" do
    get("/", StatusController, :status)
    forward("/", VersionedRouter)
  end
end
