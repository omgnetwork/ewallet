defmodule AdminAPI.Router do
  use AdminAPI, :router
  alias AdminAPI.StatusController
  alias AdminAPI.VersionedRouter
  alias EWallet.Web.SwaggerUIPlug

  get "/admin/api/", StatusController, :status

  forward "/admin/api/docs", SwaggerUIPlug, otp_app: :admin_api
  forward "/admin/api/swagger", SwaggerUIPlug, otp_app: :admin_api # Deprecated since Mar 7, 2018
  forward "/admin/api/", VersionedRouter
end
