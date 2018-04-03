defmodule EWalletDB.Account do
  @moduledoc """
  Ecto Schema representing account.
  """
  use EWalletDB.Schema
  use Arc.Ecto.Schema
  import EWalletDB.{AccountValidator, Helpers.Preloader}
  alias Ecto.Multi
  alias EWalletDB.{Account, APIKey, Balance, Key, Membership, MintedToken}

  @primary_key {:id, UUID, autogenerate: true}

  # The number of child levels allowed in the system.
  #   0 = no child levels allowed
  #   1 = one master account and its immediate children
  #   2 = one master account and 2 child levels below it
  #   3 = ...
  @child_level_limit 1

  schema "account" do
    external_id prefix: "acc_"

    field :name, :string
    field :description, :string
    field :relative_depth, :integer, virtual: true
    field :avatar, EWalletDB.Uploaders.Avatar.Type
    field :metadata, :map, default: %{}
    field :encrypted_metadata, Cloak.EncryptedMapField, default: %{}
    field :encryption_version, :binary

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

  @spec changeset(account :: %Account{}, attrs :: map()) :: Ecto.Changeset.t
  defp changeset(%Account{} = account, attrs) do
    account
    |> cast(attrs, [:name, :description, :parent_id, :metadata, :encrypted_metadata])
    |> validate_required([:name, :metadata, :encrypted_metadata])
    |> validate_parent_id()
    |> validate_account_level(@child_level_limit)
    |> unique_constraint(:name)
    |> assoc_constraint(:parent)
    |> put_change(:encryption_version, Cloak.version)
  end

  @spec avatar_changeset(changeset :: Ecto.Changeset.t, attrs :: map()) :: Ecto.Changeset.t
  defp avatar_changeset(changeset, attrs) do
    changeset
    |> cast_attachments(attrs, [:avatar])
  end

  @doc """
  Create a new account with the passed attributes, as well as a primary and a burn balances.
  """
  @spec insert(attrs :: map()) :: {:ok, %Account{}} | {:error, Ecto.Changeset.t}
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
  @spec update(account :: %Account{}, attrs :: map()) ::
    {:ok, %Account{}} | {:error, Ecto.Changeset.t}
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
  Inserts a balance for the given account.
  """
  @spec insert_balance(account :: %Account{}, identifier :: String.t) ::
    {:ok, %Balance{}} | {:error, Ecto.Changeset.t}
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
  @spec store_avatar(account :: %Account{}, attrs :: map()) :: %Account{}
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
  Get all accounts.
  """
  @spec all(opts :: keyword()) :: list(__MODULE__.t())
  def all(opts \\ [])
  def all(opts) do
    Account
    |> Repo.all()
    |> preload_option(opts)
  end

  @doc """
  Retrieves an account with the given external ID.
  """
  @spec get(ExternalID.t(), keyword()) :: __MODULE__.t() | nil
  def get(external_id, opts \\ [])
  def get(nil, _), do: nil
  def get(external_id, opts) do
    get_by([external_id: external_id], opts)
  end

  @doc """
  Retrieves an account using one or more fields.
  """
  @spec get_by(map() | keyword(), keyword()) :: %Account{}
  def get_by(fields, opts \\ []) do
    Account
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Returns whether the account is the master account.
  """
  @spec master?(account :: %Account{}) :: boolean()
  def master?(account) do
    is_nil(account.parent_id)
  end

  @doc """
  Get the master account for the current wallet setup.
  """
  @spec get_preloaded_primary_balance(opts :: keyword()) :: %Account{}
  def get_master_account(opts \\ []) do
    Account
    |> where([a], is_nil(a.parent_id))
    |> Repo.one()
    |> preload_option(opts)
  end

  @doc """
  Retrieve the primary balance for an account with preloaded balances.
  """
  @spec get_preloaded_primary_balance(account :: %Account{}) :: %Balance{}
  def get_preloaded_primary_balance(account) do
    Enum.find(account.balances, fn balance -> balance.identifier == Balance.primary end)
  end

  @doc """
  Retrieve the primary balance for an account.
  """
  @spec get_primary_balance(account :: %Account{}) :: %Balance{}
  def get_primary_balance(account) do
    get_balance_by_identifier(account, Balance.primary)
  end

  @doc """
  Retrieve the default burn balance for an account.
  """
  @spec get_default_burn_balance(account :: %Account{}) :: %Balance{}
  def get_default_burn_balance(account) do
    get_balance_by_identifier(account, Balance.burn)
  end

  @doc """
  Retrieve a balance by name for the given account.
  """
  @spec get_balance_by_identifier(account :: %Account{}, identifier :: String.t) :: %Balance{}
  def get_balance_by_identifier(account, identifier) do
    Balance
    |> where([b], b.identifier == ^identifier)
    |> where([b], b.account_id == ^account.id)
    |> Repo.one()
  end

  @doc """
  Determine the relative depth to the master account.

  The master account has a relative depth of 0.
  """
  @spec get_depth(account :: %Account{} | account_id :: String.t) :: non_neg_integer()
  def get_depth(%Account{} = account), do: get_depth(account.id)
  def get_depth(account_id) do
    case Account.get_master_account() do
      nil ->
        0 # No master account means that this account is at level 0.
      master_account ->
        account_id
        |> query_depth(master_account.id)
        |> Repo.one()
    end
  end

  @spec query_depth(account_id :: String.t, parent_account_id :: String.t) :: Ecto.Query.t
  defp query_depth(account_id, parent_account_id) do
    # Traverses up the account tree and count each step up until it reaches the master account.
    from a in Account,
      join: account_tree in fragment("""
        WITH RECURSIVE account_tree AS (
          SELECT id, parent_id, 0 AS depth
          FROM account a
          WHERE a.id = ?
        UNION
          SELECT parent.id, parent.parent_id, account_tree.depth + 1 as depth
          FROM account parent
          JOIN account_tree ON account_tree.parent_id = parent.id
        )
        SELECT id, depth FROM account_tree
        WHERE account_tree.id = ?
        """,
        type(^account_id, UUID), type(^parent_account_id, UUID)
      ), on: a.id == account_tree.id,
      select: account_tree.depth
  end
end
