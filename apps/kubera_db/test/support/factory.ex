defmodule KuberaDB.Factory do
  @moduledoc """
  Factories used for testing.
  """
  use ExMachina.Ecto, repo: KuberaDB.Repo
  alias ExMachina.Strategy
  alias KuberaDB.{Account, APIKey, AuthToken, Balance, Key, Mint,
    MintedToken, User, Transfer}
  alias Ecto.UUID

  @doc """
  Get factory name (as atom) from schema.

  The function should explicitly handle schemas that produce incorrect factory name,
  e.g. when APIKey becomes :a_p_i_key
  """
  def get_factory(APIKey), do: :api_key
  def get_factory(schema) when is_atom(schema) do
    schema
    |> struct
    |> Strategy.name_from_struct
  end

  def balance_factory do
    %Balance{
      address: sequence("address"),
      user: insert(:user),
      minted_token: nil,
      metadata: %{}
    }
  end

  def minted_token_factory do
    %MintedToken{
      friendly_id: sequence("jon") <> ":" <> UUID.generate(),
      symbol: sequence("jon"),
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
    }
  end

  def user_factory do
    %User{
      username: sequence("johndoe"),
      provider_user_id: sequence("provider_id"),
      metadata: %{
        "first_name" => sequence("John"),
        "last_name" => sequence("Doe")
      }
    }
  end

  def mint_factory do
    %Mint{
      amount: 100_000,
      minted_token_id: insert(:minted_token).id
    }
  end

  def account_factory do
    %Account{
      name: sequence("account"),
      description: sequence("description for account"),
      master: true,
    }
  end

  def key_factory do
    %Key{
      access_key: sequence("access_key"),
      secret_key: sequence("secret_key"),
      account: insert(:account),
    }
  end

  def api_key_factory do
    %APIKey{
      key: sequence("api_key"),
      account: insert(:account),
      expired: false,
    }
  end

  def auth_token_factory do
    %AuthToken{
      token: sequence("auth_token"),
      user: insert(:user),
      expired: false,
    }
  end

  def transfer_factory do
    %Transfer{
      idempotency_token: UUID.generate(),
      payload: %{example: "Payload"},
      metadata: %{some: "metadata"}
    }
  end
end
