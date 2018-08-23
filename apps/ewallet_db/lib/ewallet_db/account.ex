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

  alias EWalletDB.{
    Repo,
    Account,
    User,
    AccountUser,
    APIKey,
    Category,
    Key,
    Membership,
    Token,
    Wallet,
    Intersecter
  }

  alias EWalletDB.Helpers.InputAttribute

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
    field(:depth, :integer, virtual: true)
    field(:path, :string, virtual: true)
    field(:relative_depth, :integer, virtual: true)
    field(:avatar, EWalletDB.Uploaders.Avatar.Type)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, EWalletDB.Encrypted.Map, default: %{})

    many_to_many(
      :categories,
      Category,
      join_through: "account_category",
      join_keys: [account_uuid: :uuid, category_uuid: :uuid],
      on_replace: :delete
    )

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

  @spec changeset(%Account{}, map()) :: Ecto.Changeset.t()
  defp changeset(%Account{} = account, attrs) do
    account
    |> cast(attrs, [:name, :description, :parent_uuid, :metadata, :encrypted_metadata])
    |> validate_required([:name, :metadata, :encrypted_metadata])
    |> validate_parent_uuid()
    |> validate_account_level(@child_level_limit)
    |> unique_constraint(:name)
    |> assoc_constraint(:parent)
    |> put_categories(attrs, :category_ids)
  end

  defp put_categories(changeset, attrs, attr_name) do
    case InputAttribute.get(attrs, attr_name) do
      ids when is_list(ids) ->
        put_categories(changeset, ids)

      _ ->
        changeset
    end
  end

  defp put_categories(changeset, category_ids) do
    # Associations need to be preloaded before updating
    changeset = Map.put(changeset, :data, Repo.preload(changeset.data, :categories))
    categories = Repo.all(from(c in Category, where: c.id in ^category_ids))
    put_assoc(changeset, :categories, categories)
  end

  @spec avatar_changeset(Ecto.Changeset.t() | %Account{}, map()) ::
          Ecto.Changeset.t() | %Account{} | no_return()
  defp avatar_changeset(changeset, attrs) do
    cast_attachments(changeset, attrs, [:avatar])
  end

  @doc """
  Create a new account with the passed attributes, as well as a primary and a burn wallets.
  """
  @spec insert(map()) :: {:ok, %Account{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    multi =
      Multi.new()
      |> Multi.insert(:account, changeset(%Account{}, attrs))
      |> Multi.run(:wallet, fn %{account: account} ->
        _ = insert_wallet(account, Wallet.primary())
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
  @spec update(%Account{}, map()) :: {:ok, %Account{}} | {:error, Ecto.Changeset.t()}
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
  @spec insert_wallet(%Account{}, String.t()) :: {:ok, %Wallet{}} | {:error, Ecto.Changeset.t()}
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
  @spec store_avatar(%Account{}, map()) :: %Account{} | nil | no_return()
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
  @spec all(keyword()) :: list(%Account{})
  def all(opts \\ [])

  def all(opts) do
    Account
    |> Repo.all()
    |> preload_option(opts)
  end

  def where_in(query, uuids) do
    where(query, [a], a.uuid in ^uuids)
  end

  @doc """
  Retrieves an account with the given ID.
  """
  @spec get(String.t(), keyword()) :: %Account{} | nil | no_return()
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

  @doc """
  Retrieves an account using one or more fields.
  """
  @spec get_by(map() | keyword(), keyword()) :: %Account{} | nil | no_return()
  def get_by(fields, opts \\ []) do
    Account
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Returns whether the account is the master account.
  """
  @spec master?(%Account{}) :: boolean()
  def master?(account) do
    is_nil(account.parent_uuid)
  end

  @doc """
  Get the master account for the current wallet setup.
  """
  @spec get_master_account(keyword()) :: %Account{} | nil
  def get_master_account(opts \\ []) do
    Account
    |> where([a], is_nil(a.parent_uuid))
    |> Repo.one()
    |> preload_option(opts)
  end

  @doc """
  Fetches the master account for the current eWallet setup.

  Returns `{:ok, account}` when successful, or `{:error, :missing_master_account}` on failure.
  """
  @spec fetch_master_account(keyword()) :: {:ok, %Account{}} | {:error, :missing_master_account}
  def fetch_master_account(opts \\ []) do
    case get_master_account(opts) do
      %__MODULE__{} = account ->
        {:ok, account}

      _ ->
        {:error, :missing_master_account}
    end
  end

  @doc """
  Retrieve the primary wallet for an account with preloaded wallets.
  """
  @spec get_preloaded_primary_wallet(%Account{}) :: %Wallet{} | nil
  def get_preloaded_primary_wallet(account) do
    Enum.find(account.wallets, fn wallet -> wallet.identifier == Wallet.primary() end)
  end

  @doc """
  Retrieve the primary wallet for an account.
  """
  @spec get_primary_wallet(%Account{}) :: %Wallet{}
  def get_primary_wallet(account) do
    get_wallet_by_identifier(account, Wallet.primary())
  end

  @doc """
  Retrieve the default burn wallet for an account.
  """
  @spec get_default_burn_wallet(%Account{}) :: %Wallet{}
  def get_default_burn_wallet(account) do
    get_wallet_by_identifier(account, Wallet.burn())
  end

  @doc """
  Retrieve a wallet by name for the given account.
  """
  @spec get_wallet_by_identifier(%Account{}, String.t()) :: %Wallet{} | nil | no_return()
  def get_wallet_by_identifier(account, identifier) do
    Wallet
    |> where([b], b.identifier == ^identifier)
    |> where([b], b.account_uuid == ^account.uuid)
    |> Repo.one()
  end

  def get_all_users(account_uuids) do
    User
    |> query_all_users(account_uuids)
    |> Repo.all()
  end

  def query_all_users(query, account_uuids) do
    from(
      user in query,
      join: account_user in AccountUser,
      on: account_user.user_uuid == user.uuid,
      distinct: true,
      where: account_user.account_uuid in ^account_uuids
    )
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

  @spec query_depth(String.t(), String.t()) :: Ecto.Queryable.t()
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

  @spec descendant?(%Account{}, String.t() | [String.t()]) :: boolean()
  def descendant?(ancestor, descendant_uuids) when is_list(descendant_uuids) do
    ancestor_descendant_uuids = get_all_descendants_uuids(ancestor)

    case Intersecter.intersect(ancestor_descendant_uuids, descendant_uuids) do
      [] -> false
      _ -> true
    end
  end

  def descendant?(ancestor, descendant_uuid_or_id) do
    ancestor
    |> get_all_descendants()
    |> Enum.any?(fn descendant ->
      descendant.id == descendant_uuid_or_id || descendant.uuid == descendant_uuid_or_id
    end)
  end

  @spec get_all_descendants_uuids(%Account{} | [String.t()]) :: [String.t()]
  def get_all_descendants_uuids(account_uuids) when is_list(account_uuids) do
    account_uuids
    |> get_all_descendants()
    |> Enum.map(fn account -> account.uuid end)
  end

  def get_all_descendants_uuids(account) do
    account
    |> get_all_descendants()
    |> Enum.map(fn account -> account.uuid end)
  end

  @spec get_all_ancestors_uuids(%Account{}) :: [String.t()]
  def get_all_ancestors_uuids(account) do
    account
    |> get_all_ancestors()
    |> Enum.map(fn account -> account.uuid end)
  end

  @spec get_all_descendants([String.t()]) :: [%Account{}]
  def get_all_descendants(account_uuids) when is_list(account_uuids) do
    binary_account_uuids =
      Enum.map(account_uuids, fn account_uuid ->
        {:ok, binary_uuid} = UUID.dump(account_uuid)
        binary_uuid
      end)

    {:ok, result} =
      Repo.query(
        "
      WITH RECURSIVE accounts_cte(uuid, id, name, parent_uuid, depth, path) AS (
        SELECT current_account.uuid, current_account.id, current_account.name,
               current_account.parent_uuid, 0 AS depth, current_account.uuid::TEXT AS path
        FROM account AS current_account WHERE current_account.uuid = ANY($1)
      UNION ALL
       SELECT child.uuid, child.id, child.name, child.parent_uuid, parent.depth,
              (parent.path || '->' || child.uuid::TEXT)
       FROM accounts_cte AS parent, account AS child WHERE child.parent_uuid = parent.uuid
      )
      SELECT DISTINCT * FROM accounts_cte
      ",
        [binary_account_uuids]
      )

    load_accounts(result)
  end

  @spec get_all_descendants(%Account{}) :: [%Account{}]
  def get_all_descendants(%Account{} = account) do
    get_family_tree(account, "
      WITH RECURSIVE accounts_cte(uuid, id, name, parent_uuid, depth, path) AS (
        SELECT current_account.uuid, current_account.id, current_account.name,
               current_account.parent_uuid, $1::INT AS depth, current_account.uuid::TEXT AS path
        FROM account AS current_account WHERE current_account.uuid = $2
      UNION ALL
       SELECT child.uuid, child.id, child.name, child.parent_uuid, parent.depth + 1 AS depth,
              (parent.path || '->' || child.uuid::TEXT)
       FROM accounts_cte AS parent, account AS child WHERE child.parent_uuid = parent.uuid
      )
      SELECT * FROM accounts_cte ORDER BY depth ASC
      ")
  end

  @spec get_all_ancestors([String.t()]) :: [%Account{}] | no_return()
  def get_all_ancestors(account_uuids) when is_list(account_uuids) do
    binary_account_uuids =
      Enum.map(account_uuids, fn account_uuid ->
        {:ok, binary_uuid} = UUID.dump(account_uuid)
        binary_uuid
      end)

    {:ok, result} =
      Repo.query(
        "
        WITH RECURSIVE accounts_cte(uuid, id, name, parent_uuid, depth, path) AS (
          SELECT current_account.uuid, current_account.id, current_account.name,
                 current_account.parent_uuid, 0 AS depth, current_account.uuid::TEXT AS path
          FROM account AS current_account WHERE current_account.uuid  = ANY($1)
        UNION ALL
         SELECT child.uuid, child.id, child.name, child.parent_uuid, parent.depth - 1 AS depth,
                (parent.path || '<-' || child.uuid::TEXT)
         FROM accounts_cte AS parent, account AS child WHERE child.uuid = parent.parent_uuid
        )
        SELECT * FROM accounts_cte ORDER BY depth ASC
      ",
        [binary_account_uuids]
      )

    load_accounts(result)
  end

  @spec get_all_ancestors(%Account{}) :: [%Account{}]
  def get_all_ancestors(account) do
    get_family_tree(account, "
      WITH RECURSIVE accounts_cte(uuid, id, name, parent_uuid, depth, path) AS (
        SELECT current_account.uuid, current_account.id, current_account.name,
               current_account.parent_uuid, $1::INT AS depth, current_account.uuid::TEXT AS path
        FROM account AS current_account WHERE current_account.uuid = $2
      UNION ALL
       SELECT child.uuid, child.id, child.name, child.parent_uuid, parent.depth - 1 AS depth,
              (parent.path || '<-' || child.uuid::TEXT)
       FROM accounts_cte AS parent, account AS child WHERE child.uuid = parent.parent_uuid
      )
      SELECT * FROM accounts_cte ORDER BY depth ASC
    ")
  end

  @spec get_family_tree(%Account{}, String.t()) :: [%Account{}] | no_return()
  defp get_family_tree(account, query) do
    depth = get_depth(account.uuid)
    {:ok, binary_uuid} = UUID.dump(account.uuid)
    {:ok, result} = Repo.query(query, [depth, binary_uuid])
    load_accounts(result)
  end

  @spec load_accounts(%{:num_rows => any(), :rows => any()}) :: [%Account{}] | no_return()
  defp load_accounts(query_result) do
    Enum.map(query_result.rows, fn row ->
      Account
      |> Repo.load({query_result.columns, row})
      |> Map.put(:depth, Enum.at(row, 4))
      |> Map.put(:path, Enum.at(row, 5))
    end)
  end

  @spec add_category(%Account{}, %Category{}) :: {:ok, %Account{}} | {:error, Ecto.Changeset.t()}
  def add_category(account, category) do
    account = Repo.preload(account, :categories)

    category_ids =
      account
      |> Map.fetch!(:categories)
      |> Enum.map(fn existing -> existing.id end)
      |> List.insert_at(0, category.id)

    Account.update(account, %{category_ids: category_ids})
  end

  @spec remove_category(%Account{}, %Category{}) ::
          {:ok, %Account{}} | {:error, Ecto.Changeset.t()}
  def remove_category(account, category) do
    account = Repo.preload(account, :categories)

    remaining =
      Enum.reject(account.categories, fn existing ->
        existing.id == category.id
      end)

    category_ids = Enum.map(remaining, fn c -> c.id end)

    Account.update(account, %{category_ids: category_ids})
  end
end
