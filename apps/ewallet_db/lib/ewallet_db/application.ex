# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWalletDB.Application do
  @moduledoc """
  The EWalletDB Data Store

  Kebura's data store lives in this application.
  """
  use Application
  alias EWalletConfig.Config

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:ewallet_db)

    settings = Application.get_env(:ewallet_db, :settings)
    Config.register_and_load(:ewallet_db, settings)

    ActivityLogger.configure(%{
      EWalletDB.Seeder => "seeder",
      EWalletDB.User => "user",
      EWalletDB.Invite => "invite",
      EWalletDB.Key => "key",
      EWalletDB.ForgetPasswordRequest => "forget_password_request",
      EWalletDB.UpdateEmailRequest => "update_email_request",
      EWalletDB.AccountUser => "account_user",
      EWalletDB.Transaction => "transaction",
      EWalletDB.Mint => "mint",
      EWalletDB.TransactionRequest => "transaction_request",
      EWalletDB.TransactionConsumption => "transaction_consumption",
      EWalletDB.Account => "account",
      EWalletDB.Category => "category",
      EWalletDB.ExchangePair => "exchange_pair",
      EWalletDB.Wallet => "wallet",
      EWalletDB.Membership => "membership",
      EWalletDB.AuthToken => "auth_token",
      EWalletDB.APIKey => "api_key",
      EWalletDB.Token => "token",
      EWalletDB.Role => "role"
    })

    # Config.configure_file_storage()

    # List all child processes to be supervised
    children = [
      supervisor(EWalletDB.Repo, [])
    ]

    children =
      case Application.get_env(:ewallet_db, :file_storage_adapter) do
        "gcs" -> children ++ [supervisor(Goth.Supervisor, [])]
        _ -> children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EWalletDB.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
