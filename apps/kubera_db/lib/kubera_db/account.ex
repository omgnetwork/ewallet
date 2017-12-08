defmodule KuberaDB.Account do
  @moduledoc """
  Ecto Schema representing account.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Ecto.UUID
  alias KuberaDB.{Repo, Account, APIKey, Balance, Key, MintedToken}
  alias Ecto.Multi
  alias KuberaDB.Helpers

  @primary_key {:id, UUID, autogenerate: true}

  schema "account" do
    field :name, :string
    field :description, :string
    field :master, :boolean, default: false
    has_many :balances, Balance
    has_many :minted_tokens, MintedToken
    has_many :keys, Key
    has_many :api_keys, APIKey

    timestamps()
  end

  defp changeset(%Account{} = account, attrs) do
    account
    |> cast(attrs, [:name, :description, :master])
    |> validate_required(:name)
    |> unique_constraint(:name)
  end

  @doc """
  Create a new account with the passed attributes, as well as a primary and a burn balances.
  """
  def insert(attrs) do
    multi =
      Multi.new
      |> Multi.insert(:account, changeset(%Account{}, attrs))
      |> Multi.run(:balance, fn %{account: account} ->
        insert_balance(account, Balance.primary)
        insert_balance(account, Balance.burn)
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        account = result.account |> Repo.preload([:balances])
        {:ok, account}
      # Only the account insertion should fail. If the balance insert fails, there is
      # something wrong with our code.
      {:error, _failed_operation, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end

  @doc """
  Inserts a balance for the given account.
  """
  def insert_balance(%Account{} = account, identifier) do
    %{
      account_id: account.id,
      name: identifier,
      identifier: identifier,
      metadata: %{}
    }
    |> Balance.insert()
  end

  @doc """
  Retrieve the account with the given ID.
  """
  def get(id) do
    case Helpers.UUID.valid?(id) do
      true -> Repo.get(Account, id)
      false -> nil
    end
  end

  @doc """
  Retrieve the account with the given ID and preloads balances.
  """
  def get(id, %{preload: true}) do
    id
    |> get()
    |> Repo.preload([:balances])
  end

  @doc """
  Retrieve the account with the given name.
  """
  def get_by_name(name) when is_binary(name) and byte_size(name) > 0 do
    Repo.get_by(Account, name: name)
  end

  @doc """
  Get the master account for the current wallet setup.
  """
  def get_master_account(true) do
    get_master_account()
    |> Repo.preload([:balances])
  end
  def get_master_account do
    Account
    |> where([a], a.master == true)
    |> Repo.one()
  end

  @doc """
  Retrieve the primary balance for an account.
  """
  def get_primary_balance(account) do
    get_balance_by_identifier(account, Balance.primary)
  end

  @doc """
  Retrieve the default burn balance for an account.
  """
  def get_default_burn_balance(account) do
    get_balance_by_identifier(account, Balance.burn)
  end

  @doc """
  Retrieve a balance by name for the given account.
  """
  def get_balance_by_identifier(account, identifier) do
    Balance
    |> where([b], b.identifier == ^identifier)
    |> where([b], b.account_id == ^account.id)
    |> Repo.one()
  end
end
