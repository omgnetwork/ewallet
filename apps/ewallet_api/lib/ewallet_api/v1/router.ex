# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWalletAPI.V1.Router do
  @moduledoc """
  Routes for the eWallet API endpoints.
  """
  use EWalletAPI, :router
  alias EWalletAPI.V1.ClientAuthPlug
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

    # Simulate a server error. Useful for testing the internal server error response
    # and error reporting. Locked behind authentication to prevent spamming.
    post("/status.server_error", StatusController, :server_error)
  end

  # Standalone endpoints
  scope "/", EWalletAPI.V1 do
    pipe_through([:api, :standalone])

    post("/user.signup", SignupController, :signup)
    post("/user.verify_email", SignupController, :verify_email)
    post("/user.login", AuthController, :login)

    post("/user.reset_password", ResetPasswordController, :reset)
    post("/user.update_password", ResetPasswordController, :update)
  end

  # Public endpoints
  scope "/", EWalletAPI.V1 do
    pipe_through([:api])

    post("/status", StatusController, :index)

    match(:*, "/*path", FallbackController, :not_found)
  end
end
