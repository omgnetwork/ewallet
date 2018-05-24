defmodule EWalletDB.Account do
  @moduledoc """
  Ecto Schema representing account.
  """
  use Ecto.Schema
  use Arc.Ecto.Schema
  use EWalletDB.Types.ExternalID
  import Ecto.{Changeset, Query}
  import EWalletDB.{AccountValidator, Helpers.Preloader}
  alias Ecto.{Multi, UUID}
  alias EWalletDB.{Repo, Account, APIKey, Wallet, Key, Membership, Token}

  @primary_key {:uuid, UUID, autogenerate: true}

  # The number of child levels allowed in the system.
  #   0 = no child levels allowed
  #   1 = one master account and its immediate children
  #   2 = one master account and 2 child levels below it
  #   3 = ...
  @child_level_limit 1

  schema "account" do
    external_id(prefix: "acc_")

    field(:name, :string)
    field(:description, :string)
    field(:relative_depth, :integer, virtual: true)
    field(:avatar, EWalletDB.Uploaders.Avatar.Type)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, Cloak.EncryptedMapField, default: %{})
    field(:encryption_version, :binary)

    belongs_to(
      :parent,
      Account,
      foreign_key: :parent_uuid,
      references: :uuid,
      type: UUID
    )

    has_many(
      :wallets,
      Wallet,
      foreign_key: :account_uuid,
      references: :uuid
    )

    has_many(
      :tokens,
      Token,
      foreign_key: :account_uuid,
      references: :uuid
    )

    has_many(
      :keys,
      Key,
      foreign_key: :account_uuid,
      references: :uuid
    )

    has_many(
      :api_keys,
      APIKey,
      foreign_key: :account_uuid,
      references: :uuid
    )

    has_many(
      :memberships,
      Membership,
      foreign_key: :account_uuid,
      references: :uuid
    )

    timestamps()
  end

  @spec changeset(account :: %Account{}, attrs :: map()) :: Ecto.Changeset.t()
  defp changeset(%Account{} = account, attrs) do
    account
    |> cast(attrs, [:name, :description, :parent_uuid, :metadata, :encrypted_metadata])
    |> validate_required([:name, :metadata, :encrypted_metadata])
    |> validate_parent_uuid()
    |> validate_account_level(@child_level_limit)
    |> unique_constraint(:name)
    |> assoc_constraint(:parent)
    |> put_change(:encryption_version, Cloak.version())
  end

  @spec avatar_changeset(changeset :: Ecto.Changeset.t(), attrs :: map()) :: Ecto.Changeset.t()
  defp avatar_changeset(changeset, attrs) do
    changeset
    |> cast_attachments(attrs, [:avatar])
  end

  @doc """
  Create a new account with the passed attributes, as well as a primary and a burn wallets.
  """
  @spec insert(attrs :: map()) :: {:ok, %Account{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    multi =
      Multi.new()
      |> Multi.insert(:account, changeset(%Account{}, attrs))
      |> Multi.run(:wallet, fn %{account: account} ->
        insert_wallet(account, Wallet.primary())
        insert_wallet(account, Wallet.burn())
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        account = result.account |> Repo.preload([:wallets])
        {:ok, account}

      # Only the account insertion should fail. If the wallet insert fails, there is
      # something wrong with our code.
      {:error, _failed_operation, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates an account with the provided attributes.
  """
  @spec update(account :: %Account{}, attrs :: map()) ::
          {:ok, %Account{}} | {:error, Ecto.Changeset.t()}
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
  Inserts a wallet for the given account.
  """
  @spec insert_wallet(account :: %Account{}, identifier :: String.t()) ::
          {:ok, %Wallet{}} | {:error, Ecto.Changeset.t()}
  def insert_wallet(%Account{} = account, identifier) do
    %{
      account_uuid: account.uuid,
      name: identifier,
      identifier: identifier,
      metadata: %{}
    }
    |> Wallet.insert()
  end

  @doc """
  Stores an avatar for the given account.
  """
  @spec store_avatar(account :: %Account{}, attrs :: map()) :: %Account{}
  def store_avatar(%Account{} = account, attrs) do
    attrs =
      case attrs["avatar"] do
        "" -> %{avatar: nil}
        "null" -> %{avatar: nil}
        avatar -> %{avatar: avatar}
      end

    changeset = avatar_changeset(account, attrs)

    case Repo.update(changeset) do
      {:ok, account} -> get(account.id)
      result -> result
    end
  end

  @doc """
  Get all accounts.
  """
  @spec all(opts :: keyword()) :: list(%Account{})
  def all(opts \\ [])

  def all(opts) do
    Account
    |> Repo.all()
    |> preload_option(opts)
  end

  @doc """
  Retrieves an account with the given ID.
  """
  @spec get(id :: ExternalID.t(), opts :: keyword()) :: %Account{} | nil
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

  @doc """
  Retrieves an account using one or more fields.
  """
  @spec get_by(fields :: map(), opts :: keyword()) :: %Account{}
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
    is_nil(account.parent_uuid)
  end

  @doc """
  Get the master account for the current wallet setup.
  """
  @spec get_preloaded_primary_wallet(opts :: keyword()) :: %Account{}
  def get_master_account(opts \\ []) do
    Account
    |> where([a], is_nil(a.parent_uuid))
    |> Repo.one()
    |> preload_option(opts)
  end

  @doc """
  Retrieve the primary wallet for an account with preloaded wallets.
  """
  @spec get_preloaded_primary_wallet(account :: %Account{}) :: %Wallet{}
  def get_preloaded_primary_wallet(account) do
    Enum.find(account.wallets, fn wallet -> wallet.identifier == Wallet.primary() end)
  end

  @doc """
  Retrieve the primary wallet for an account.
  """
  @spec get_primary_wallet(account :: %Account{}) :: %Wallet{}
  def get_primary_wallet(account) do
    get_wallet_by_identifier(account, Wallet.primary())
  end

  @doc """
  Retrieve the default burn wallet for an account.
  """
  @spec get_default_burn_wallet(account :: %Account{}) :: %Wallet{}
  def get_default_burn_wallet(account) do
    get_wallet_by_identifier(account, Wallet.burn())
  end

  @doc """
  Retrieve a wallet by name for the given account.
  """
  @spec get_wallet_by_identifier(account :: %Account{}, identifier :: String.t()) :: %Wallet{}
  def get_wallet_by_identifier(account, identifier) do
    Wallet
    |> where([b], b.identifier == ^identifier)
    |> where([b], b.account_uuid == ^account.uuid)
    |> Repo.one()
  end

  @doc """
  Determine the relative depth to the master account.

  Returns a non-negative integer if the account is found.
  The master account has a relative depth of 0.

  It raises an error if passed nil, because a nil does not belong to any account level.
  And it is unsafe to default it, for example, to being a top level account.
  """
  @spec get_depth(%Account{} | String.t()) :: non_neg_integer() | no_return()
  def get_depth(%Account{} = account), do: get_depth(account.uuid)

  def get_depth(account_uuid) when not is_nil(account_uuid) do
    case Account.get_master_account() do
      nil ->
        # No master account means that this account is at level 0.
        0

      master_account ->
        account_uuid
        |> query_depth(master_account.uuid)
        |> Repo.one()
    end
  end

  @spec query_depth(account_uuid :: String.t(), parent_uuid :: String.t()) :: Ecto.Query.t()
  defp query_depth(account_uuid, parent_uuid) do
    # Traverses up the account tree and count each step up until it reaches the master account.
    from(
      a in Account,
      join:
        account_tree in fragment(
          """
          WITH RECURSIVE account_tree AS (
            SELECT uuid, parent_uuid, 0 AS depth
            FROM account a
            WHERE a.uuid = ?
          UNION
            SELECT parent.uuid, parent.parent_uuid, account_tree.depth + 1 as depth
            FROM account parent
            JOIN account_tree ON account_tree.parent_uuid = parent.uuid
          )
          SELECT uuid, depth FROM account_tree
          WHERE account_tree.uuid = ?
          """,
          type(^account_uuid, UUID),
          type(^parent_uuid, UUID)
        ),
      on: a.uuid == account_tree.uuid,
      select: account_tree.depth
    )
  end
end
