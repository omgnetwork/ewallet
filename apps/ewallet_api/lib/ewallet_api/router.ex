defmodule EWalletAPI.Router do
  use EWalletAPI, :router
  alias EWalletAPI.StatusController
  alias EWalletAPI.VersionedRouter
  alias EWallet.Web.SwaggerUIPlug

  get "/api/", StatusController, :status

  forward "/api/docs", SwaggerUIPlug, otp_app: :ewallet_api
  forward "/api/swagger", SwaggerUIPlug, otp_app: :ewallet_api # Deprecated since Mar 7, 2018
  forward "/api/", VersionedRouter
end
