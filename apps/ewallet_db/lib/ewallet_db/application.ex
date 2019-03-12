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

defmodule EWalletDB.Application do
  @moduledoc """
  The EWalletDB Data Store

  The eWallet's data store lives in this application.
  """
  use Application
  alias Appsignal.Ecto
  alias EWalletConfig.Config

  def start(_type, _args) do
    import Supervisor.Spec
    DeferredConfig.populate(:ewallet_db)

    settings = Application.get_env(:ewallet_db, :settings)
    Config.register_and_load(:ewallet_db, settings)

    ActivityLogger.configure(%{
      EWalletDB.Seeder => %{type: "seeder", identifier: nil},
      EWalletDB.User => %{type: "user", identifier: :id},
      EWalletDB.Invite => %{type: "invite", identifier: nil},
      EWalletDB.Key => %{type: "key", identifier: :id},
      EWalletDB.ForgetPasswordRequest => %{type: "forget_password_request", identifier: nil},
      EWalletDB.UpdateEmailRequest => %{type: "update_email_request", identifier: nil},
      EWalletDB.AccountUser => %{type: "account_user", identifier: nil},
      EWalletDB.Transaction => %{type: "transaction", identifier: :id},
      EWalletDB.Mint => %{type: "mint", identifier: :id},
      EWalletDB.TransactionRequest => %{type: "transaction_request", identifier: :id},
      EWalletDB.TransactionConsumption => %{type: "transaction_consumption", identifier: :id},
      EWalletDB.Account => %{type: "account", identifier: :id},
      EWalletDB.Category => %{type: "category", identifier: :id},
      EWalletDB.ExchangePair => %{type: "exchange_pair", identifier: :id},
      EWalletDB.Wallet => %{type: "wallet", identifier: :address},
      EWalletDB.Membership => %{type: "membership", identifier: :id},
      EWalletDB.AuthToken => %{type: "auth_token", identifier: :id},
      EWalletDB.APIKey => %{type: "api_key", identifier: :id},
      EWalletDB.Token => %{type: "token", identifier: :id},
      EWalletDB.Role => %{type: "role", identifier: :id}
    })

    :telemetry.attach(
      "appsignal-ecto",
      [:ewallet_db, :repo, :query],
      &Ecto.handle_event/4,
      nil
    )

    # List all child processes to be supervised
    children = [
      supervisor(EWalletDB.Repo, []),
      supervisor(EWalletDB.Vault, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EWalletDB.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
