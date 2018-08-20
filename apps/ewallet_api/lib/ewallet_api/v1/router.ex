defmodule EWalletAPI.V1.Router do
  use EWalletAPI, :router
  alias EWalletAPI.V1.Plug.ClientAuthPlug
  alias EWalletAPI.V1.StandalonePlug

  pipeline :client_api do
    plug(ClientAuthPlug)
  end

  pipeline :standalone do
    plug(StandalonePlug)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # Client endpoints
  scope "/", EWalletAPI.V1 do
    pipe_through([:api, :client_api])

    post("/me.get", SelfController, :get)
    post("/me.get_settings", SelfController, :get_settings)
    post("/me.get_wallets", SelfController, :get_wallets)
    post("/me.get_transactions", TransactionController, :get_transactions)

    post("/me.create_transaction_request", TransactionRequestController, :create_for_user)
    post("/me.get_transaction_request", TransactionRequestController, :get)
    post("/me.create_transaction", TransactionController, :create)

    post(
      "/me.approve_transaction_consumption",
      TransactionConsumptionController,
      :approve_for_user
    )

    post("/me.reject_transaction_consumption", TransactionConsumptionController, :reject_for_user)
    post("/me.consume_transaction_request", TransactionConsumptionController, :consume_for_user)

    post("/me.logout", AuthController, :logout)
  end

  # Standalone endpoints
  scope "/", EWalletAPI.V1 do
    pipe_through([:api, :standalone])

    post("/user.signup", SignupController, :signup)
    post("/user.verify_email", SignupController, :verify_email)
    post("/user.login", AuthController, :login)
  end

  # Public endpoints
  scope "/", EWalletAPI.V1 do
    pipe_through([:api])

    post("/status", StatusController, :index)
    post("/status.server_error", StatusController, :server_error)

    match(:*, "/*path", FallbackController, :not_found)
  end
end
