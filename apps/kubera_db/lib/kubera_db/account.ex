defmodule KuberaDB.Account do
  @moduledoc """
  Ecto Schema representing account.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias KuberaDB.{Repo, Account, APIKey, Balance, Key, MintedToken}

  @primary_key {:id, UUID, autogenerate: true}

  schema "account" do
    field :name, :string
    field :description, :string
    field :master, :boolean
    has_many :balances, Balance
    has_many :minted_tokens, MintedToken
    has_many :keys, Key
    has_many :api_keys, APIKey

    timestamps()
  end

  @doc """
  Validates account data.
  """
  def changeset(%Account{} = account, attrs) do
    account
    |> cast(attrs, [:name, :description, :master])
    |> validate_required(:name)
    |> unique_constraint(:name)
  end

  @doc """
  Create a new account with the passed attributes.
  """
  def insert(attrs) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end
end
