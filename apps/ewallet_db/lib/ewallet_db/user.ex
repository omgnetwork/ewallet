defmodule EWalletDB.User do
  @moduledoc """
  Ecto Schema representing users.
  """
  use Ecto.Schema
  use Arc.Ecto.Schema
  import Ecto.{Changeset, Query}
  import EWalletDB.Validator
  alias Ecto.{Multi, UUID}
  alias EWalletDB.{Repo, Account, AuthToken, Balance, Invite,
                   Membership, Role, User, Helpers, Helpers.Crypto}

  @primary_key {:id, UUID, autogenerate: true}

  schema "user" do
    field :username, :string
    field :email, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :password_hash, :string
    field :provider_user_id, :string
    field :metadata, :map, default: %{}
    field :encrypted_metadata, Cloak.EncryptedMapField, default: %{}
    field :encryption_version, :binary
    field :avatar, EWalletDB.Uploaders.Avatar.Type

    belongs_to :invite, Invite, type: UUID
    has_many :balances, Balance
    has_many :auth_tokens, AuthToken
    has_many :memberships, Membership
    many_to_many :roles, Role, join_through: Membership
    many_to_many :accounts, Account, join_through: Membership

    timestamps()
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:username, :provider_user_id, :email, :password,
                    :password_confirmation, :metadata, :encrypted_metadata,
                    :invite_id])
    |> validate_required([:metadata, :encrypted_metadata])
    |> validate_confirmation(:password, message: "does not match password!")
    |> validate_immutable(:provider_user_id)
    |> unique_constraint(:username)
    |> unique_constraint(:provider_user_id)
    |> unique_constraint(:email)
    |> assoc_constraint(:invite)
    |> put_change(:password_hash, Crypto.hash_password(attrs[:password]))
    |> put_change(:encryption_version, Cloak.version)
    |> validate_by_roles(attrs)
  end

  defp avatar_changeset(changeset, attrs) do
    changeset
    |> cast_attachments(attrs, [:avatar])
  end

  # Two cases to validate for loginable:
  #
  #   1. A new admin user has just been created. No membership assgined yet.
  #      So `do_validate_loginable/2` if email is provided.
  #   2. An existing provider user has been assigned a membership. No email provided yet.
  #      So `do_validate_loginable/2` if membership exists.
  #
  # If neither conditions are met, then we can be certain that the user is a provider user.
  defp validate_by_roles(changeset, attrs) do
    user = apply_changes(changeset)

    cond do
      user.email != nil ->
        do_validate_loginable(changeset, attrs)
      User.has_membership?(user) ->
        do_validate_loginable(changeset, attrs)
      true ->
        do_validate_provider_user(changeset, attrs)
    end
  end

  defp do_validate_loginable(changeset, _attrs) do
    changeset
    |> validate_required([:email, :password])
    |> validate_password(:password)
  end

  defp do_validate_provider_user(changeset, _attrs) do
    validate_required(changeset, [:username, :provider_user_id])
  end

  @doc """
  Retrieves all the addresses for the given user.
  """
  def addresses(user) do
    user = user |> Repo.preload(:balances)
    Enum.map(user.balances, fn balance ->
      balance.address
    end)
  end

  @doc """
  Retrieves a specific user.
  """
  def get(id, queryable \\ User) do
    case Helpers.UUID.valid?(id) do
      true ->
        queryable
        |> Repo.get(id)
        |> Repo.preload(:balances)
      false -> nil
    end
  end

  @doc """
  Retrieves a specific user from its provider_user_id.
  """
  def get_by_provider_user_id(nil), do: nil
  def get_by_provider_user_id(provider_user_id) do
    User
    |> Repo.get_by(provider_user_id: provider_user_id)
    |> Repo.preload(:balances)
  end

  @doc """
  Retrieves a specific user from its email.
  """
  def get_by_email(email) when is_binary(email) do
    User
    |> Repo.get_by(email: email)
    |> Repo.preload(:balances)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> insert(%{field: value})
      {:ok, %User{}}

  Creates a user and their primary balance.
  """
  def insert(attrs) do
    multi =
      Multi.new
      |> Multi.insert(:user, changeset(%User{}, attrs))
      |> Multi.run(:balance, fn %{user: user} ->
        insert_balance(user, Balance.primary)
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        user = result.user |> Repo.preload([:balances])
        {:ok, user}
      # Only the account insertion should fail. If the balance insert fails, there is
      # something wrong with our code.
      {:error, _failed_operation, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end

  @doc """
  Inserts a balance for the given user.
  """
  def insert_balance(%User{} = user, identifier) do
    %{
      user_id: user.id,
      name: identifier,
      identifier: identifier
    }
    |> Balance.insert()
  end

  @doc """
  Updates a user with the provided attributes.
  """
  def update(%User{} = user, attrs) do
    changeset = changeset(user, attrs)

    case Repo.update(changeset) do
      {:ok, user} ->
        {:ok, get(user.id)}
      result ->
        result
    end
  end

  @doc """
  Stores an avatar for the given user.
  """
  def store_avatar(%User{} = user, attrs) do
    attrs =
      case attrs["avatar"] do
        ""     -> %{avatar: nil}
        "null" -> %{avatar: nil}
        avatar -> %{avatar: avatar}
      end

    changeset = avatar_changeset(user, attrs)
    case Repo.update(changeset) do
      {:ok, user} -> get(user.id)
      result      -> result
    end
  end

  @doc """
  Retrieve the primary balance for a user.
  """
  def get_primary_balance(user) do
    Balance
    |> where([b], b.user_id == ^user.id)
    |> where([b], b.identifier == ^Balance.primary)
    |> Repo.one()
  end

  @doc """
  Retrieve the primary balance for a user with preloaded balances.
  """
  def get_preloaded_primary_balance(user) do
    Enum.find(user.balances, fn balance -> balance.identifier == Balance.primary end)
  end

  @doc """
  Retrieves the status of the given user.
  """
  def get_status(user) do
    if user.invite_id == nil, do: :active, else: :pending_confirmation
  end

  @doc """
  Retrieves the user's invite if any.
  """
  def get_invite(user) do
    user
    |> Repo.preload(:invite)
    |> Map.fetch!(:invite)
  end

  @doc """
  Checks if the user belongs to any account, regardless of the role.
  """
  # User does not have any membership if it has not been saved yet.
  # Without pattern matching for nil id, Ecto will return an unsafe nil comparison error.
  def has_membership?(%{id: nil}), do: false
  def has_membership?(user) do
    query = from(m in Membership, where: m.user_id == ^user.id)
    Repo.aggregate(query, :count, :id) > 0
  end

  @doc """
  Checks if the user is assigned to the given role, regardless of which account.
  """
  def has_role?(user, role) do
    user
    |> User.get_roles()
    |> Enum.member?(role)
  end

  @doc """
  Get the list of unique roles that the given user is assigned to, regardless of the account.

  This is useful when a check is required on a role but not depending on the account.
  E.g. if the user is an admin, an email and password is required regardless of which account.
  """
  def get_roles(user) do
    user
    |> Repo.preload(:roles)
    |> Map.get(:roles, [])
    |> Enum.map(fn(role) -> Map.fetch!(role, :name) end)
    |> Enum.uniq()
  end

  @doc """
  Retrieves the user's role on the given account.

  If the user does not have a membership on the given account, it inherits
  the role from the closest parent account that has one.
  """
  def get_role(user_id, account_id) do
    with {:ok, user_id} <- UUID.cast(user_id),
         {:ok, account_id} <- UUID.cast(account_id),
         query <- query_role(user_id, account_id)
    do
      Repo.one(query)
    else
      :error ->
        {:error, :invalid_parameter}
    end
  end

  defp query_role(user_id, account_id) do
    # Traverses up the account tree to find the user's role in the closest parent.
    from r in Role,
      join: account_tree in fragment("""
        WITH RECURSIVE account_tree AS (
          SELECT a.*, m.role_id, m.user_id
          FROM account a
          LEFT JOIN membership AS m ON m.account_id = a.id
          WHERE a.id = ?
        UNION
          SELECT parent.*, m.role_id, m.user_id
          FROM account parent
          LEFT JOIN membership AS m ON m.account_id = parent.id
          JOIN account_tree ON account_tree.parent_id = parent.id
        )
        SELECT role_id FROM account_tree
        JOIN role AS r ON r.id = role_id
        WHERE account_tree.user_id = ? LIMIT 1
      """,
        type(^account_id, UUID),
        type(^user_id, UUID)
      ), on: r.id == account_tree.role_id,
      select: r.name
  end

  @doc """
  Retrieves the upper-most account that the given user has membership in.
  """
  def get_account(user) do
    query = from [q, child] in query_accounts(user),
      order_by: [asc: child.depth],
      limit: 1

    Repo.one(query)
  end

  @doc """
  Retrieves the list of accounts that the given user has membership, including their child accounts.
  """
  def get_accounts(user) do
    user
    |> query_accounts()
    |> Repo.all()
  end

  @doc """
  Query the list of accounts that the given user has membership, including their child accounts.
  """
  def query_accounts(user) do
    account_ids =
      user
      |> Membership.all_by_user()
      |> Enum.map(fn(m) -> Map.fetch!(m, :account_id) end)

    # Traverses down the account tree
    from a in Account,
      join: child in fragment("""
        WITH RECURSIVE account_tree AS (
          SELECT account.*, 0 AS depth
          FROM account
          WHERE account.id = ANY(?)
        UNION
          SELECT child.*, account_tree.depth + 1 as depth
          FROM account child
          JOIN account_tree ON account_tree.id = child.parent_id
        ) SELECT * FROM account_tree
      """, type(^account_ids, {:array, :binary_id})), on: a.id == child.id,
      select: %{a | relative_depth: child.depth}
  end
end
