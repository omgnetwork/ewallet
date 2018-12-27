defmodule AdminAPI.V1.Router do
  @moduledoc """
  Routes for the Admin API endpoints.
  """
  use AdminAPI, :router
  alias AdminAPI.V1.AdminAPIAuthPlug

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

    # Exchange pair endpoints
    post("/exchange_pair.all", ExchangePairController, :all)
    post("/exchange_pair.get", ExchangePairController, :get)
    post("/exchange_pair.create", ExchangePairController, :create)
    post("/exchange_pair.update", ExchangePairController, :update)
    post("/exchange_pair.delete", ExchangePairController, :delete)

    # Token endpoints
    post("/token.all", TokenController, :all)
    post("/token.get", TokenController, :get)
    post("/token.create", TokenController, :create)
    post("/token.update", TokenController, :update)
    post("/token.enable_or_disable", TokenController, :enable_or_disable)
    post("/token.stats", TokenController, :stats)
    post("/token.get_mints", MintController, :all_for_token)
    post("/token.mint", MintController, :mint)

    # Transaction endpoints
    post("/transaction.all", TransactionController, :all)
    post("/transaction.get", TransactionController, :get)
    post("/transaction.create", TransactionController, :create)
    post("/transaction.calculate", TransactionCalculationController, :calculate)

    post("/transaction_request.all", TransactionRequestController, :all)
    post("/transaction_request.create", TransactionRequestController, :create)
    post("/transaction_request.get", TransactionRequestController, :get)
    post("/transaction_request.consume", TransactionConsumptionController, :consume)

    post(
      "/transaction_request.get_transaction_consumptions",
      TransactionConsumptionController,
      :all_for_transaction_request
    )

    post("/transaction_consumption.all", TransactionConsumptionController, :all)
    post("/transaction_consumption.get", TransactionConsumptionController, :get)
    post("/transaction_consumption.approve", TransactionConsumptionController, :approve)
    post("/transaction_consumption.reject", TransactionConsumptionController, :reject)

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
    post("/account.get_users", UserController, :all_for_account)
    post("/account.get_descendants", AccountController, :descendants_for_account)
    post("/account.get_transactions", TransactionController, :all_for_account)
    post("/account.get_transaction_requests", TransactionRequestController, :all_for_account)

    post(
      "/account.get_transaction_consumptions",
      TransactionConsumptionController,
      :all_for_account
    )

    # Account membership endpoints
    post("/account.get_members", AccountMembershipController, :all_for_account)
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
    post("/user.get_transaction_consumptions", TransactionConsumptionController, :all_for_user)
    post("/user.enable_or_disable", UserController, :enable_or_disable)

    # Wallet endpoints
    post("/wallet.all", WalletController, :all)
    post("/wallet.get", WalletController, :get)
    post("/wallet.create", WalletController, :create)
    post("/wallet.enable_or_disable", WalletController, :enable_or_disable)

    post(
      "/wallet.get_transaction_consumptions",
      TransactionConsumptionController,
      :all_for_wallet
    )

    # Admin endpoints
    post("/admin.all", AdminUserController, :all)
    post("/admin.get", AdminUserController, :get)
    post("/admin.enable_or_disable", AdminUserController, :enable_or_disable)

    # Role endpoints
    post("/role.all", RoleController, :all)
    post("/role.get", RoleController, :get)
    post("/role.create", RoleController, :create)
    post("/role.update", RoleController, :update)
    post("/role.delete", RoleController, :delete)

    # API Access endpoints
    post("/access_key.all", KeyController, :all)
    post("/access_key.create", KeyController, :create)
    post("/access_key.enable_or_disable", KeyController, :enable_or_disable)
    post("/access_key.delete", KeyController, :delete)

    # Deprecated in PR #535
    post("/access_key.update", KeyController, :update)

    # API Key endpoints
    post("/api_key.all", APIKeyController, :all)
    post("/api_key.create", APIKeyController, :create)
    post("/api_key.enable_or_disable", APIKeyController, :enable_or_disable)
    post("/api_key.delete", APIKeyController, :delete)

    # Deprecated in PR #535
    post("/api_key.update", APIKeyController, :update)

    # Settings endpoint
    post("/settings.all", SettingsController, :get_settings)

    # Configuration endpoint
    post("/configuration.all", ConfigurationController, :all)
    post("/configuration.update", ConfigurationController, :update)

    # Activity logs endpoint
    post("/activity_log.all", ActivityLogController, :all)

    # Self endpoints (operations on the currently authenticated user)
    post("/me.get", SelfController, :get)
    post("/me.get_accounts", SelfController, :get_accounts)
    post("/me.get_account", SelfController, :get_account)
    post("/me.update", SelfController, :update)
    post("/me.update_password", SelfController, :update_password)
    post("/me.update_email", SelfController, :update_email)
    post("/me.upload_avatar", SelfController, :upload_avatar)

    post("/me.logout", AdminAuthController, :logout)

    # Simulate a server error. Useful for testing the internal server error response
    # and error reporting. Locked behind authentication to prevent spamming.
    post("/status.server_error", StatusController, :server_error)
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

    # Verifying email update request is unauthenticated, because the user
    # may be opening and verifying the email from a different device.
    post("/admin.verify_email_update", SelfController, :verify_email)

    post("/status", StatusController, :index)

    match(:*, "/*path", FallbackController, :not_found)
  end
end
