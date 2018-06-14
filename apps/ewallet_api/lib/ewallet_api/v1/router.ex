defmodule EWalletAPI.V1.Router do
  use EWalletAPI, :router
  alias EWalletAPI.V1.Plug.Idempotency
  alias EWalletAPI.V1.Plug.ClientAuth

  pipeline :client_api do
    plug(ClientAuth)
  end

  pipeline :idempotency do
    plug(Idempotency)
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

    post(
      "/me.approve_transaction_consumption",
      TransactionConsumptionController,
      :approve_for_user
    )

    post("/me.reject_transaction_consumption", TransactionConsumptionController, :reject_for_user)

    scope "/" do
      pipe_through([:idempotency])
      post("/me.consume_transaction_request", TransactionConsumptionController, :consume_for_user)
      post("/me.transfer", TransferController, :transfer_for_user)
    end

    post("/logout", AuthController, :logout)
  end

  # Public endpoints
  scope "/", EWalletAPI.V1 do
    pipe_through([:api])

    post("/status", StatusController, :index)
    post("/status.server_error", StatusController, :server_error)

    match(:*, "/*path", FallbackController, :not_found)
  end
end
