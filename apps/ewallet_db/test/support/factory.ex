defmodule EWalletDB.Factory do
  @moduledoc """
  Factories used for testing.
  """
  use ExMachina.Ecto, repo: EWalletDB.Repo
  alias ExMachina.Strategy

  alias EWalletDB.{
    Account,
    APIKey,
    AuthToken,
    Category,
    ForgetPasswordRequest,
    Invite,
    Key,
    Membership,
    Mint,
    Token,
    Role,
    TransactionRequest,
    TransactionConsumption,
    Transfer,
    User,
    Wallet
  }

  alias EWalletDB.Helpers.Crypto
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
      name: sequence("Category name")
    }
  end

  def wallet_factory do
    %Wallet{
      address: sequence("address"),
      name: sequence("name"),
      identifier: Wallet.primary(),
      user: insert(:user),
      token: nil,
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
      account: insert(:account)
    }
  end

  def user_factory do
    %User{
      username: sequence("johndoe"),
      provider_user_id: sequence("provider_id"),
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
      email: sequence("johndoe") <> "@example.com",
      password: password,
      password_hash: Crypto.hash_password(password),
      invite: nil,
      metadata: %{
        "first_name" => sequence("John"),
        "last_name" => sequence("Doe")
      }
    }
  end

  def invite_factory do
    %Invite{
      token: Crypto.generate_key(32)
    }
  end

  def role_factory do
    %Role{
      name: sequence("role"),
      display_name: "Role display name"
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
      transfer_uuid: insert(:transfer).uuid
    }
  end

  def account_factory do
    %Account{
      name: sequence("account"),
      description: sequence("description for account"),
      parent: Account.get_master_account()
    }
  end

  def key_factory do
    access_key = sequence("access_key")
    secret_key = sequence("secret_key")

    %Key{
      access_key: access_key,
      secret_key: secret_key,
      secret_key_hash: Crypto.hash_password(secret_key),
      account: insert(:account),
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

  def transfer_factory do
    %Transfer{
      idempotency_token: UUID.generate(),
      payload: %{example: "Payload"},
      metadata: %{some: "metadata"},
      amount: 100,
      token: insert(:token),
      from_wallet: insert(:wallet),
      to_wallet: insert(:wallet)
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
