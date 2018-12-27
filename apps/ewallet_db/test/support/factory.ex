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

defmodule EWalletDB.Factory do
  @moduledoc """
  Factories used for testing.
  """
  use ExMachina.Ecto, repo: EWalletDB.Repo
  alias ExMachina.Strategy
  alias Utils.{Types.WalletAddress, Helpers.Crypto}
  alias ActivityLogger.{System, ActivityLog}

  alias EWalletDB.{
    Account,
    AccountUser,
    APIKey,
    AuthToken,
    Category,
    Export,
    ExchangePair,
    ForgetPasswordRequest,
    Invite,
    Key,
    Membership,
    Mint,
    Role,
    Token,
    Transaction,
    TransactionConsumption,
    TransactionRequest,
    UpdateEmailRequest,
    User,
    Wallet
  }

  alias Ecto.UUID
  alias ExULID.ULID

  @doc """
  Get factory name (as atom) from schema.

  The function should explicitly handle schemas that produce incorrect factory name,
  e.g. when APIKey becomes :a_p_i_key
  """
  def get_factory(APIKey), do: :api_key

  def get_factory(schema) when is_atom(schema) do
    schema
    |> struct
    |> Strategy.name_from_struct()
  end

  def export_factory do
    %Export{
      schema: "transaction",
      filename: sequence("filename"),
      format: "csv",
      status: "completed",
      completion: 100,
      url: nil,
      path: "/my/path",
      failure_reason: nil,
      estimated_size: 100_000,
      total_count: 100,
      adapter: "local",
      params: %{"sort_by" => "created_at", "sort_dir" => "desc"},
      originator: %System{}
    }
  end

  def category_factory do
    %Category{
      name: sequence("Category name"),
      description: sequence("description"),
      originator: %System{}
    }
  end

  def exchange_pair_factory do
    %ExchangePair{
      from_token: insert(:token),
      to_token: insert(:token),
      rate: 1.0,
      originator: %System{}
    }
  end

  def wallet_factory do
    {:ok, address} = WalletAddress.generate()

    %Wallet{
      address: address,
      name: sequence("Wallet name"),
      identifier: Wallet.primary(),
      user: insert(:user),
      enabled: true,
      metadata: %{},
      originator: %System{}
    }
  end

  def token_factory do
    symbol = sequence("jon")

    %Token{
      id: "tok_" <> symbol <> "_" <> ULID.generate(),
      symbol: symbol,
      iso_code: sequence("JON"),
      name: sequence("John Currency"),
      description: sequence("Official currency of Johndoeland"),
      short_symbol: sequence("J"),
      subunit: "Doe",
      subunit_to_unit: 100,
      symbol_first: true,
      html_entity: "&curren;",
      iso_numeric: sequence("990"),
      smallest_denomination: 1,
      locked: false,
      account: insert(:account),
      enabled: true,
      originator: %System{}
    }
  end

  def user_factory do
    %User{
      is_admin: false,
      email: nil,
      username: sequence("johndoe"),
      full_name: sequence("John Doe"),
      calling_name: sequence("John"),
      provider_user_id: sequence("provider_id"),
      enabled: true,
      metadata: %{
        "first_name" => sequence("John"),
        "last_name" => sequence("Doe")
      },
      encrypted_metadata: %{},
      originator: %System{}
    }
  end

  def standalone_user_factory do
    password = sequence("password")

    %User{
      is_admin: false,
      email: sequence("johndoe") <> "@example.com",
      password: password,
      password_hash: Crypto.hash_password(password),
      metadata: %{
        "first_name" => sequence("John"),
        "last_name" => sequence("Doe")
      },
      encrypted_metadata: %{},
      originator: %System{}
    }
  end

  def admin_factory do
    password = sequence("password")

    %User{
      is_admin: true,
      email: sequence("johndoe") <> "@example.com",
      password: password,
      password_hash: Crypto.hash_password(password),
      invite: nil,
      metadata: %{
        "first_name" => sequence("John"),
        "last_name" => sequence("Doe")
      },
      originator: %System{}
    }
  end

  def invite_factory do
    %Invite{
      user: nil,
      token: Crypto.generate_base64_key(32),
      success_url: nil,
      verified_at: nil,
      originator: %System{}
    }
  end

  def role_factory do
    %Role{
      name: sequence("role"),
      display_name: "Role display name",
      priority: sequence(""),
      originator: %System{}
    }
  end

  def membership_factory do
    %Membership{
      user: insert(:user),
      role: insert(:role),
      account: insert(:account),
      originator: %System{}
    }
  end

  def mint_factory do
    %Mint{
      amount: 100_000,
      token_uuid: insert(:token).uuid,
      transaction_uuid: insert(:transaction).uuid,
      originator: %System{}
    }
  end

  def account_factory do
    %Account{
      name: sequence("account"),
      description: sequence("description for account"),
      parent: Account.get_master_account(),
      originator: %System{}
    }
  end

  def account_user_factory do
    %AccountUser{
      account_uuid: Account.get_master_account().uuid,
      user_uuid: insert(:user).uuid,
      originator: %System{}
    }
  end

  def key_factory do
    access_key = sequence("access_key")
    secret_key = sequence("secret_key")

    %Key{
      access_key: access_key,
      secret_key: Base.url_encode64(secret_key, padding: false),
      secret_key_hash: Crypto.hash_secret(secret_key),
      account: insert(:account),
      enabled: true,
      deleted_at: nil,
      originator: %System{}
    }
  end

  def api_key_factory do
    %APIKey{
      key: sequence("api_key"),
      owner_app: "some_app_name",
      account: insert(:account),
      enabled: true,
      originator: %System{}
    }
  end

  def auth_token_factory do
    %AuthToken{
      token: sequence("auth_token"),
      owner_app: "some_app_name",
      user: insert(:user),
      account: insert(:account),
      expired: false,
      originator: %System{}
    }
  end

  def transaction_factory do
    token = insert(:token)
    from_wallet = insert(:wallet)
    to_wallet = insert(:wallet)

    %Transaction{
      idempotency_token: UUID.generate(),
      payload: %{example: "Payload"},
      metadata: %{some: "metadata"},
      from_amount: 100,
      from_token: token,
      from_wallet: from_wallet,
      from_user_uuid: from_wallet.user_uuid,
      from_account_uuid: from_wallet.account_uuid,
      to_token: token,
      to_amount: 100,
      to_wallet: to_wallet,
      to_user_uuid: to_wallet.user_uuid,
      to_account_uuid: to_wallet.account_uuid,
      exchange_account: nil,
      originator: %System{}
    }
  end

  def forget_password_request_factory do
    %ForgetPasswordRequest{
      token: sequence("123"),
      enabled: true,
      originator: %System{},
      expires_at: NaiveDateTime.utc_now() |> NaiveDateTime.add(60 * 10)
    }
  end

  def update_email_request_factory do
    %UpdateEmailRequest{
      email: sequence("johndoe") <> "@example.com",
      token: sequence("123"),
      enabled: true,
      originator: %System{}
    }
  end

  def transaction_request_factory do
    %TransactionRequest{
      type: "receive",
      amount: 100,
      correlation_id: sequence("correlation"),
      token_uuid: insert(:token).uuid,
      user_uuid: insert(:user).uuid,
      wallet: insert(:wallet),
      consumptions_count: 0,
      originator: %System{}
    }
  end

  def transaction_consumption_factory do
    %TransactionConsumption{
      idempotency_token: sequence("123"),
      token_uuid: insert(:token).uuid,
      user_uuid: insert(:user).uuid,
      wallet_address: insert(:wallet).address,
      amount: 100,
      transaction_request_uuid: insert(:transaction_request).uuid,
      originator: %System{}
    }
  end

  def activity_log_factory do
    system = %System{}

    %ActivityLog{
      action: "insert",
      target_type: ActivityLog.get_type(system.__struct__),
      target_uuid: system.uuid,
      target_changes: %{some: "change"},
      originator_uuid: system.uuid,
      originator_type: ActivityLog.get_type(system.__struct__),
      inserted_at: NaiveDateTime.utc_now()
    }
  end

  def activity_log_preloaded_factory do
    admin = insert(:admin)
    account = insert(:account)

    %ActivityLog{
      action: "insert",
      target_type: ActivityLog.get_type(account.__struct__),
      target_uuid: account.uuid,
      target_changes: %{description: "description changed"},
      originator_uuid: admin.uuid,
      originator_type: ActivityLog.get_type(admin.__struct__),
      inserted_at: NaiveDateTime.utc_now()
    }
    |> Map.put(:originator, admin)
    |> Map.put(:target, account)
  end
end
