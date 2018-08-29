defmodule EWalletAPI.V1.PageRouter do
  @moduledoc """
  Routes for html pages.
  """
  use EWalletAPI, :router
  alias EWalletAPI.V1.StandalonePlug

  pipeline :pages do
    plug(:accepts, ["html"])
    plug(:put_layout, {EWalletAPI.V1.LayoutView, :layout})
  end

  pipeline :standalone do
    plug(StandalonePlug)
  end

  # Pages for standalone functionalities
  scope "/", EWalletAPI.V1 do
    pipe_through([:pages, :standalone])

    get("/verify_email", VerifyEmailController, :verify)
    get("/verify_email/success", VerifyEmailController, :success)
  end
end
