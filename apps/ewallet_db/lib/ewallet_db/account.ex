defmodule EWalletDB.Account do
  @moduledoc """
  Ecto Schema representing account.
  """
  use Ecto.Schema
  use Arc.Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Ecto.{Multi, UUID}
  alias EWalletDB.{Repo, Account, APIKey, Balance, Key, Membership, MintedToken}
  alias EWalletDB.Helpers

  @primary_key {:id, UUID, autogenerate: true}

  schema "account" do
    field :name, :string
    field :description, :string
    field :master, :boolean, default: false
    field :relative_depth, :integer, virtual: true
    field :avatar, EWalletDB.Uploaders.Avatar.Type

    belongs_to :parent, Account, foreign_key: :parent_id, # this column
                                 references: :id, # the parent's column
                                 type: UUID
    has_many :balances, Balance
    has_many :minted_tokens, MintedToken
    has_many :keys, Key
    has_many :api_keys, APIKey
    has_many :memberships, Membership

    timestamps()
  end

  defp changeset(%Account{} = account, attrs) do
    account
    |> cast(attrs, [:name, :description, :master, :parent_id])
    |> validate_required(:name)
    |> unique_constraint(:name)
    |> assoc_constraint(:parent)
  end

  defp avatar_changeset(changeset, attrs) do
    changeset
    |> cast_attachments(attrs, [:avatar])
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
  Updates an account with the provided attributes.
  """
  def update(%Account{} = account, attrs) do
    changeset = changeset(account, attrs)

    case Repo.update(changeset) do
      {:ok, account} ->
        {:ok, get(account.id)}
      result ->
        result
    end
  end

  @doc """
  Get all accounts.
  """
  def all do
    Repo.all(Account)
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
  Stores an avatar for the given account.
  """
  def store_avatar(%Account{} = account, attrs) do
    attrs =
      case attrs["avatar"] do
        ""     -> %{avatar: nil}
        "null" -> %{avatar: nil}
        avatar -> %{avatar: avatar}
      end

    changeset = avatar_changeset(account, attrs)

    case Repo.update(changeset) do
      {:ok, account} -> get(account.id)
      result         -> result
    end
  end

  @doc """
  Retrieve the account with the given ID.
  """
  def get(nil), do: nil
  def get(id) do
    case Helpers.UUID.valid?(id) do
      true -> Repo.get(Account, id)
      false -> nil
    end
  end

  @doc """
  Retrieve the account with the given ID and preloads balances.
  """
  def get(id, preload: preloads) do
    id
    |> get()
    |> Repo.preload(preloads)
  end

  @doc """
  Retrieve the account with the given name.
  """
  def get_by_name(nil), do: nil
  def get_by_name(name) when is_binary(name) and byte_size(name) > 0 do
    Repo.get_by(Account, name: name)
  end

  @doc """
  Returns whether the account is the master account.
  """
  def is_master?(account) do
    # Currently there is `master` field on the account so we use that value.
    # We have this function because soon the field be removed and the master account
    # will need to be determined by checking that the account's `parent_id` is nil.
    account.master
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
  Retrieve the primary balance for an account with preloaded balances.
  """
  def get_preloaded_primary_balance(account) do
    Enum.find(account.balances, fn balance -> balance.identifier == Balance.primary end)
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
