defmodule AdminAPI.V1.Router do
  use AdminAPI, :router
  alias AdminAPI.V1.{ClientAuthPlug, AdminAPIAuthPlug}

  # Pipeline for plugs to apply for all endpoints
  pipeline :api do
    plug(:accepts, ["json"])
  end

  # Pipeline for endpoints that require user authentication or provider
  # authentication
  pipeline :admin_api do
    plug(AdminAPIAuthPlug)
  end

  # Authenticated endpoints
  scope "/", AdminAPI.V1 do
    pipe_through([:api, :admin_api])

    post("/auth_token.switch_account", AdminAuthController, :switch_account)

    # Token endpoints
    post("/token.all", TokenController, :all)
    post("/token.get", TokenController, :get)
    post("/token.create", TokenController, :create)
    post("/token.stats", TokenController, :stats)
    post("/token.get_mints", MintController, :all_for_token)
    post("/token.mint", MintController, :mint)

    # Transaction endpoints
    post("/transaction.all", TransactionController, :all)
    post("/transaction.get", TransactionController, :get)

    post("/transaction_request.create", TransactionRequestController, :create)
    post("/transaction_request.get", TransactionRequestController, :get)
    post("/transaction_consumption.approve", TransactionConsumptionController, :approve)
    post("/transaction_consumption.reject", TransactionConsumptionController, :reject)

    post("/transaction.create", TransactionController, :create)
    post("/user.credit_wallet", TransferController, :credit)
    post("/user.debit_wallet", TransferController, :debit)
    post("/transfer", TransferController, :transfer)
    post("/transaction_request.consume", TransactionConsumptionController, :consume)

    # Category endpoints
    post("/category.all", CategoryController, :all)
    post("/category.get", CategoryController, :get)
    post("/category.create", CategoryController, :create)
    post("/category.update", CategoryController, :update)
    post("/category.delete", CategoryController, :delete)

    # Account endpoints
    post("/account.all", AccountController, :all)
    post("/account.get", AccountController, :get)
    post("/account.create", AccountController, :create)
    post("/account.update", AccountController, :update)
    post("/account.upload_avatar", AccountController, :upload_avatar)
    post("/account.get_wallets", WalletController, :all_for_account)

    # Account membership endpoints
    post("/account.get_users", AccountMembershipController, :get_users)
    post("/account.assign_user", AccountMembershipController, :assign_user)
    post("/account.unassign_user", AccountMembershipController, :unassign_user)

    # User endpoints
    post("/user.all", UserController, :all)
    post("/user.get", UserController, :get)
    post("/user.login", UserAuthController, :login)
    post("/user.logout", UserAuthController, :logout)
    post("/user.create", UserController, :create)
    post("/user.update", UserController, :update)
    post("/user.get_wallets", WalletController, :all_for_user)
    post("/user.get_transactions", TransactionController, :all_for_user)

    # Wallet endpoints
    post("/wallet.all", WalletController, :all)
    post("/wallet.get", WalletController, :get)
    post("/wallet.create", WalletController, :create)

    # Admin endpoints
    post("/admin.all", AdminController, :all)
    post("/admin.get", AdminController, :get)

    # API Access endpoints
    post("/access_key.all", KeyController, :all)
    post("/access_key.create", KeyController, :create)
    post("/access_key.delete", KeyController, :delete)

    post("/api_key.all", APIKeyController, :all)
    post("/api_key.create", APIKeyController, :create)
    post("/api_key.delete", APIKeyController, :delete)

    post("/settings.all", SettingsController, :get_settings)

    # Self endpoints (operations on the currently authenticated user)
    post("/me.get", SelfController, :get)
    post("/me.get_accounts", SelfController, :get_accounts)
    post("/me.get_account", SelfController, :get_account)
    post("/me.update", SelfController, :update)
    post("/me.upload_avatar", SelfController, :upload_avatar)

    post("/me.logout", AdminAuthController, :logout)
  end

  # Public endpoints and Fallback endpoints.
  # Gandles all remaining routes
  # that are not handled by the scopes above.
  scope "/", AdminAPI.V1 do
    pipe_through([:api])

    post("/admin.login", AdminAuthController, :login)
    post("/invite.accept", InviteController, :accept)

    # Forget Password endpoints
    post("/admin.reset_password", ResetPasswordController, :reset)
    post("/admin.update_password", ResetPasswordController, :update)

    post("/status", StatusController, :index)
    post("/status.server_error", StatusController, :server_error)

    match(:*, "/*path", FallbackController, :not_found)
  end
end
