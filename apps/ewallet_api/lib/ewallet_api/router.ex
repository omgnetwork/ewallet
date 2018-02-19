defmodule EWalletAPI.Router do
  use EWalletAPI, :router
  alias EWalletAPI.StatusController
  alias EWalletAPI.VersionedRouter
  alias EWallet.Web.SwaggerPlug

  get "/api/", StatusController, :status

  forward "/api/swagger", SwaggerPlug, otp_app: :ewallet_api
  forward "/api/", VersionedRouter
end
