defmodule EWalletDB.Factory do
  @moduledoc """
  Factories used for testing.
  """
  use ExMachina.Ecto, repo: EWalletDB.Repo
  alias ExMachina.Strategy

  alias EWalletDB.{
    Account,
    AccountUser,
    APIKey,
    Audit,
    AuthToken,
    Category,
    ExchangePair,
    ForgetPasswordRequest,
    Helpers.Crypto,
    Invite,
    Key,
    Membership,
    Mint,
    Role,
    System,
    Token,
    Transaction,
    TransactionConsumption,
    TransactionRequest,
    Types.WalletAddress,
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

  def category_factory do
    %Category{
      name: sequence("Category name"),
      description: sequence("description")
    }
  end

  def exchange_pair_factory do
    %ExchangePair{
      from_token: insert(:token),
      to_token: insert(:token),
      rate: 1.0
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
      metadata: %{}
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
      enabled: true
    }
  end

  def user_factory do
    %User{
      is_admin: false,
      email: nil,
      username: sequence("johndoe"),
      provider_user_id: sequence("provider_id"),
      originator: insert(:admin),
      metadata: %{
        "first_name" => sequence("John"),
        "last_name" => sequence("Doe")
      },
      encrypted_metadata: %{}
    }
  end

  def standalone_user_factory do
    password = sequence("password")

    %User{
      is_admin: false,
      email: sequence("johndoe") <> "@example.com",
      password: password,
      password_hash: Crypto.hash_password(password),
      originator: :self,
      metadata: %{
        "first_name" => sequence("John"),
        "last_name" => sequence("Doe")
      },
      encrypted_metadata: %{}
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
      originator: %System{},
      metadata: %{
        "first_name" => sequence("John"),
        "last_name" => sequence("Doe")
      }
    }
  end

  def audit_factory do
    params = params_for(:user)
    user = insert(params)
    originator = insert(:admin)

    %Audit{
      action: "insert",
      target_type: Audit.get_type(User),
      target_uuid: user.uuid,
      target_changes: params,
      originator_uuid: originator.uuid,
      originator_type: Audit.get_type(Admin)
    }
  end

  def sytem_audit_factory do
    params = params_for(:admin)
    admin = insert(params)
    originator = %System{}

    %Audit{
      action: "insert",
      target_type: Audit.get_type(admin.__struct__),
      target_uuid: admin.uuid,
      target_changes: params,
      originator_uuid: originator.uuid,
      originator_type: Audit.get_type(originator.__struct__)
    }
  end

  def invite_factory do
    %Invite{
      user: nil,
      token: Crypto.generate_base64_key(32),
      success_url: nil,
      verified_at: nil,
      originator: insert(:admin)
    }
  end

  def role_factory do
    %Role{
      name: sequence("role"),
      display_name: "Role display name",
      priority: sequence("")
    }
  end

  def membership_factory do
    %Membership{
      user: insert(:user),
      role: insert(:role),
      account: insert(:account)
    }
  end

  def mint_factory do
    %Mint{
      amount: 100_000,
      token_uuid: insert(:token).uuid,
      transaction_uuid: insert(:transaction).uuid
    }
  end

  def account_factory do
    %Account{
      name: sequence("account"),
      description: sequence("description for account"),
      parent: Account.get_master_account()
    }
  end

  def account_user_factory do
    %AccountUser{
      account_uuid: Account.get_master_account().uuid,
      user_uuid: insert(:user).uuid
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
      expired: false,
      deleted_at: nil
    }
  end

  def api_key_factory do
    %APIKey{
      key: sequence("api_key"),
      owner_app: "some_app_name",
      account: insert(:account),
      expired: false
    }
  end

  def auth_token_factory do
    %AuthToken{
      token: sequence("auth_token"),
      owner_app: "some_app_name",
      user: insert(:user),
      account: insert(:account),
      expired: false
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
      exchange_account: nil
    }
  end

  def forget_password_request_factory do
    %ForgetPasswordRequest{
      token: sequence("123")
    }
  end

  def transaction_request_factory do
    %TransactionRequest{
      type: "receive",
      amount: 100,
      correlation_id: sequence("correlation"),
      token_uuid: insert(:token).uuid,
      user_uuid: insert(:user).uuid,
      wallet: insert(:wallet)
    }
  end

  def transaction_consumption_factory do
    %TransactionConsumption{
      idempotency_token: sequence("123"),
      token_uuid: insert(:token).uuid,
      user_uuid: insert(:user).uuid,
      wallet_address: insert(:wallet).address,
      amount: 100,
      transaction_request_uuid: insert(:transaction_request).uuid
    }
  end
end
