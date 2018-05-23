defmodule EWalletDB.User do
  @moduledoc """
  Ecto Schema representing users.
  """
  use Arc.Ecto.Schema
  use Ecto.Schema
  use EWalletDB.Types.ExternalID
  import Ecto.{Changeset, Query}
  import EWalletDB.Validator
  alias Ecto.{Multi, UUID}

  alias EWalletDB.{
    Repo,
    Account,
    AuthToken,
    Wallet,
    Invite,
    Membership,
    Role,
    User,
    Helpers.Crypto
  }

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "user" do
    external_id(prefix: "usr_")

    field(:username, :string)
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, :string)
    field(:provider_user_id, :string)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, Cloak.EncryptedMapField, default: %{})
    field(:encryption_version, :binary)
    field(:avatar, EWalletDB.Uploaders.Avatar.Type)

    belongs_to(
      :invite,
      Invite,
      foreign_key: :invite_uuid,
      references: :uuid,
      type: UUID
    )

    has_many(
      :wallets,
      Wallet,
      foreign_key: :user_uuid,
      references: :uuid
    )

    has_many(
      :auth_tokens,
      AuthToken,
      foreign_key: :user_uuid,
      references: :uuid
    )

    has_many(
      :memberships,
      Membership,
      foreign_key: :user_uuid,
      references: :uuid
    )

    many_to_many(
      :roles,
      Role,
      join_through: Membership,
      join_keys: [user_uuid: :uuid, role_uuid: :uuid]
    )

    many_to_many(
      :accounts,
      Account,
      join_through: Membership,
      join_keys: [user_uuid: :uuid, account_uuid: :uuid]
    )

    timestamps()
  end

  defp changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [
      :username,
      :provider_user_id,
      :email,
      :password,
      :password_confirmation,
      :metadata,
      :encrypted_metadata,
      :invite_uuid
    ])
    |> validate_required([:metadata, :encrypted_metadata])
    |> validate_confirmation(:password, message: "does not match password!")
    |> validate_immutable(:provider_user_id)
    |> unique_constraint(:username)
    |> unique_constraint(:provider_user_id)
    |> unique_constraint(:email)
    |> assoc_constraint(:invite)
    |> put_change(:password_hash, Crypto.hash_password(attrs[:password]))
    |> put_change(:encryption_version, Cloak.version())
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
    user = user |> Repo.preload(:wallets)

    Enum.map(user.wallets, fn wallet ->
      wallet.address
    end)
  end

  @doc """
  Retrieves a specific user.
  """
  @spec get(ExternalID.t()) :: %User{} | nil
  @spec get(ExternalID.t(), Ecto.Queryable.t()) :: %User{} | nil
  def get(id, queryable \\ User)

  def get(id, queryable) when is_external_id(id) do
    queryable
    |> Repo.get_by(id: id)
    |> Repo.preload(:wallets)
  end

  def get(_, _), do: nil

  @doc """
  Retrieves a specific user from its provider_user_id.
  """
  def get_by_provider_user_id(nil), do: nil

  def get_by_provider_user_id(provider_user_id) do
    User
    |> Repo.get_by(provider_user_id: provider_user_id)
    |> Repo.preload(:wallets)
  end

  @doc """
  Retrieves a specific user from its email.
  """
  def get_by_email(email) when is_binary(email) do
    User
    |> Repo.get_by(email: email)
    |> Repo.preload(:wallets)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> insert(%{field: value})
      {:ok, %User{}}

  Creates a user and their primary wallet.
  """
  def insert(attrs) do
    multi =
      Multi.new()
      |> Multi.insert(:user, changeset(%User{}, attrs))
      |> Multi.run(:wallet, fn %{user: user} ->
        insert_wallet(user, Wallet.primary())
      end)

    case Repo.transaction(multi) do
      {:ok, result} ->
        user = result.user |> Repo.preload([:wallets])
        {:ok, user}

      # Only the account insertion should fail. If the wallet insert fails, there is
      # something wrong with our code.
      {:error, _failed_operation, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end

  @doc """
  Inserts a wallet for the given user.
  """
  def insert_wallet(%User{} = user, identifier) do
    %{
      user_uuid: user.uuid,
      name: identifier,
      identifier: identifier
    }
    |> Wallet.insert()
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
        "" -> %{avatar: nil}
        "null" -> %{avatar: nil}
        avatar -> %{avatar: avatar}
      end

    changeset = avatar_changeset(user, attrs)

    case Repo.update(changeset) do
      {:ok, user} -> get(user.id)
      result -> result
    end
  end

  @doc """
  Retrieve the primary wallet for a user.
  """
  def get_primary_wallet(user) do
    Wallet
    |> where([b], b.user_uuid == ^user.uuid)
    |> where([b], b.identifier == ^Wallet.primary())
    |> Repo.one()
  end

  @doc """
  Retrieve the primary wallet for a user with preloaded wallets.
  """
  def get_preloaded_primary_wallet(user) do
    Enum.find(user.wallets, fn wallet -> wallet.identifier == Wallet.primary() end)
  end

  @doc """
  Retrieves the status of the given user.
  """
  def get_status(user) do
    if user.invite_uuid == nil, do: :active, else: :pending_confirmation
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
  def has_membership?(%{uuid: nil}), do: false

  def has_membership?(user) do
    query = from(m in Membership, where: m.user_uuid == ^user.uuid)
    Repo.aggregate(query, :count, :uuid) > 0
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
    |> Enum.map(fn role -> Map.fetch!(role, :name) end)
    |> Enum.uniq()
  end

  @doc """
  Retrieves the user's role on the given account.

  If the user does not have a membership on the given account, it inherits
  the role from the closest parent account that has one.
  """
  @spec get_role(ExternalID.t(), ExternalID.t()) :: String.t() | nil
  def get_role(user_id, account_id) do
    user_id
    |> query_role(account_id)
    |> Repo.one()
  end

  defp query_role(user_id, account_id) do
    # Traverses up the account tree to find the user's role in the closest parent.
    from(
      r in Role,
      join:
        account_tree in fragment(
          ~s/
            WITH RECURSIVE account_tree AS (
              SELECT a.*, m.role_uuid, m.user_uuid
              FROM account a
              LEFT JOIN membership AS m ON m.account_uuid = a.uuid
              WHERE a.id = ?
            UNION
              SELECT parent.*, m.role_uuid, m.user_uuid
              FROM account parent
              LEFT JOIN membership AS m ON m.account_uuid = parent.uuid
              JOIN account_tree ON account_tree.parent_uuid = parent.uuid
            )
            SELECT role_uuid FROM account_tree
            JOIN "role" AS r ON r.uuid = role_uuid
            JOIN "user" AS u ON u.uuid = user_uuid
            WHERE u.id = ? LIMIT 1
          /,
          ^account_id,
          ^user_id
        ),
      on: r.uuid == account_tree.role_uuid,
      select: r.name
    )
  end

  @doc """
  Retrieves the upper-most account that the given user has membership in.
  """
  def get_account(user) do
    query =
      from(
        [q, child] in query_accounts(user),
        order_by: [asc: child.depth, desc: child.inserted_at],
        limit: 1
      )

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
    account_uuids =
      user
      |> Membership.all_by_user()
      |> Enum.map(fn m -> Map.fetch!(m, :account_uuid) end)

    # Traverses down the account tree
    from(
      a in Account,
      join:
        child in fragment(
          """
            WITH RECURSIVE account_tree AS (
              SELECT account.*, 0 AS depth
              FROM account
              WHERE account.uuid = ANY(?)
            UNION
              SELECT child.*, account_tree.depth + 1 as depth
              FROM account child
              JOIN account_tree ON account_tree.uuid = child.parent_uuid
            ) SELECT * FROM account_tree
          """,
          type(^account_uuids, {:array, UUID})
        ),
      on: a.uuid == child.uuid,
      select: %{a | relative_depth: child.depth}
    )
  end
end
