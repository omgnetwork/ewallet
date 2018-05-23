defmodule EWalletAPI.V1.Router do
  use EWalletAPI, :router
  alias EWallet.Web.V1.Plug.Idempotency
  alias EWalletAPI.V1.Plug.{ClientAuth, ProviderAuth}

  pipeline :provider_api do
    plug(ProviderAuth)
  end

  pipeline :client_api do
    plug(ClientAuth)
  end

  pipeline :idempotency do
    plug(Idempotency)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # Provider endpoints
  scope "/", EWalletAPI.V1 do
    pipe_through([:api, :provider_api])

    post("/user.create", UserController, :create)
    post("/user.get", UserController, :get)
    post("/user.update", UserController, :update)

    post("/user.list_wallets", WalletController, :all)
    post("/user.list_transactions", TransactionController, :all_for_user)

    post("/transaction_request.create", TransactionRequestController, :create)
    post("/transaction_request.get", TransactionRequestController, :get)
    post("/transaction_consumption.approve", TransactionConsumptionController, :approve)
    post("/transaction_consumption.reject", TransactionConsumptionController, :reject)

    post("/transaction.all", TransactionController, :all)

    # Idempotent requests
    scope "/" do
      pipe_through([:idempotency])

      post("/user.credit_wallet", TransferController, :credit)
      post("/user.debit_wallet", TransferController, :debit)
      post("/transfer", TransferController, :transfer)
      post("/transaction_request.consume", TransactionConsumptionController, :consume)
    end

    post("/login", AuthController, :login)
    post("/get_settings", SettingsController, :get_settings)
  end

  # Client endpoints
  scope "/", EWalletAPI.V1 do
    pipe_through([:api, :client_api])

    post("/me.get", SelfController, :get)
    post("/me.get_settings", SelfController, :get_settings)
    post("/me.list_wallets", SelfController, :get_wallets)
    post("/me.list_transactions", TransactionController, :get_transactions)

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
