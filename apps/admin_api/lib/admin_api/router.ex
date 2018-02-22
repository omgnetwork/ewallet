defmodule AdminAPI.Router do
  use AdminAPI, :router
  alias AdminAPI.StatusController
  alias AdminAPI.VersionedRouter
  alias EWallet.Web.SwaggerPlug

  get "/admin/api/", StatusController, :status

  forward "/admin/api/swagger", SwaggerPlug, otp_app: :admin_api
  forward "/admin/api/", VersionedRouter
end
