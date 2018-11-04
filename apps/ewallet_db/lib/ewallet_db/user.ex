defmodule EWalletDB.User do
  @moduledoc """
  Ecto Schema representing users.
  """
  use Arc.Ecto.Schema
  use Ecto.Schema
  use EWalletConfig.Types.ExternalID
  import Ecto.{Changeset, Query}
  import EWalletDB.Helpers.Preloader
  import EWalletConfig.Validator
  import EWalletDB.Validator
  alias Ecto.{Multi, UUID}
  alias EWalletConfig.Helpers.Crypto

  alias EWalletConfig.Types.VirtualStruct

  alias EWalletDB.{
    Account,
    AccountUser,
    Audit,
    AuthToken,
    Invite,
    Membership,
    Repo,
    Role,
    User,
    Wallet
  }

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "user" do
    external_id(prefix: "usr_")

    field(:is_admin, :boolean, default: false)
    field(:username, :string)
    field(:full_name, :string)
    field(:calling_name, :string)
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, :string)
    field(:provider_user_id, :string)
    field(:originator, VirtualStruct, virtual: true)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, EWalletConfig.Encrypted.Map, default: %{})
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
    password_hash = attrs |> get_attr(:password) |> Crypto.hash_password()

    changeset
    |> cast(attrs, [
      :is_admin,
      :username,
      :full_name,
      :calling_name,
      :provider_user_id,
      :email,
      :password,
      :password_confirmation,
      :metadata,
      :encrypted_metadata,
      :invite_uuid,
      :originator
    ])
    |> validate_required([:metadata, :encrypted_metadata, :originator])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_immutable(:provider_user_id)
    |> unique_constraint(:username)
    |> unique_constraint(:provider_user_id)
    |> unique_constraint(:email)
    |> assoc_constraint(:invite)
    |> put_change(:password_hash, password_hash)
    |> validate_by_roles(attrs)
  end

  defp update_user_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :username,
      :full_name,
      :calling_name,
      :provider_user_id,
      :email,
      :metadata,
      :encrypted_metadata,
      :invite_uuid,
      :originator
    ])
    |> validate_required([:metadata, :encrypted_metadata, :originator])
    |> validate_immutable(:provider_user_id)
    |> unique_constraint(:username)
    |> unique_constraint(:provider_user_id)
    |> unique_constraint(:email)
    |> assoc_constraint(:invite)
    |> validate_by_roles(attrs)
  end

  defp update_admin_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :full_name,
      :calling_name,
      :metadata,
      :encrypted_metadata,
      :invite_uuid,
      :originator
    ])
    |> validate_required([:metadata, :encrypted_metadata, :originator])
    |> unique_constraint(:email)
    |> assoc_constraint(:invite)
    |> validate_by_roles(attrs)
  end

  defp avatar_changeset(user, attrs) do
    user
    |> cast(attrs, [:originator])
    |> cast_attachments(attrs, [:avatar])
    |> validate_required([:originator])
  end

  defp password_changeset(user, attrs) do
    password_hash = attrs |> get_attr(:password) |> Crypto.hash_password()

    user
    |> cast(attrs, [
      :password,
      :password_confirmation,
      :originator
    ])
    |> validate_required([:originator])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(:password)
    |> put_change(:password_hash, password_hash)
  end

  defp get_attr(attrs, atom_field) do
    attrs[atom_field] || attrs[Atom.to_string(atom_field)]
  end

  # Two cases to validate for loginable:
  #
  #   1. A new admin user has just been created. No membership assigned yet.
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

  # The `:password` field, unlike other fields, is nil when fetched from an existing user.
  # So we need to check with `:password_hash` instead, before applying `validate_required/2`
  # on the `:password` field.
  #
  #   1. If there's already a password hash, no need to require a password,
  #      it's already loginable.
  #   2. If there isn't a password hash, require one so the user becomes loginable.

  defp do_validate_loginable(changeset, _attrs) do
    case get_field(changeset, :password_hash) do
      nil ->
        changeset
        |> validate_required([:email, :password])
        |> validate_password(:password)

      _ ->
        changeset
        |> validate_required([:email])
    end
  end

  defp do_validate_provider_user(changeset, _attrs) do
    changeset
    |> validate_required([:username, :provider_user_id])
  end

  @doc """
  Retrieves all the addresses for the given user.
  """
  @spec addresses(%User{}) :: [String.t()]
  def addresses(user) do
    user = user |> Repo.preload(:wallets)

    Enum.map(user.wallets, fn wallet ->
      wallet.address
    end)
  end

  @doc """
  Retrieves a specific user.
  """
  @spec get(String.t()) :: %User{} | nil
  @spec get(String.t(), Ecto.Queryable.t()) :: %User{} | nil
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
  @spec get_by_provider_user_id(String.t() | nil) :: %User{} | nil
  def get_by_provider_user_id(nil), do: nil

  def get_by_provider_user_id(provider_user_id) do
    User
    |> Repo.get_by(provider_user_id: provider_user_id)
    |> Repo.preload(:wallets)
  end

  @doc """
  Retrieves a specific user from its email.
  """
  @spec get_by_email(String.t()) :: %User{} | nil
  def get_by_email(email) when is_binary(email) do
    User
    |> Repo.get_by(email: email)
    |> Repo.preload(:wallets)
  end

  @doc """
  Retrieves a user using one or more fields.
  """
  @spec get_by(fields :: map() | keyword(), opts :: keyword()) :: %User{} | nil | no_return()
  def get_by(fields, opts \\ []) do
    User
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Creates a user and their primary wallet.

  ## Examples

      iex> insert(%{field: value})
      {:ok, %User{}}
  """
  @spec insert(map()) :: {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    %User{}
    |> changeset(attrs)
    |> Audit.insert_record_with_audit(
      Multi.run(Multi.new(), :wallet, fn %{record: record} ->
        case User.admin?(record) do
          true -> {:ok, nil}
          false -> insert_wallet(record, Wallet.primary())
        end
      end)
    )
    |> case do
      {:ok, result} ->
        user = Repo.preload(result.record, [:wallets])
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
  @spec insert_wallet(%User{}, String.t()) :: {:ok, %Wallet{}} | {:error, Ecto.Changeset.t()}
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
  @spec update(%User{}, map()) :: {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def update(%User{} = user, attrs) do
    changeset =
      if User.admin?(user) do
        update_admin_changeset(user, attrs)
      else
        update_user_changeset(user, attrs)
      end

    update_with_audit(changeset)
  end

  @doc """
  Updates a user's password with the provided attributes.
  """
  @spec update_password(%User{}, map(), keyword()) ::
          {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def update_password(%User{} = user, attrs, opts \\ []) do
    if opts[:ignore_current] do
      do_update_password(user, attrs)
    else
      do_verify_and_update_password(user, attrs)
    end
  end

  defp do_verify_and_update_password(user, attrs) do
    old_password = attrs[:old_password] || attrs["old_password"]

    cond do
      old_password == nil && user.password_hash == nil ->
        do_update_password(user, attrs)

      old_password == nil && user.password_hash != nil ->
        {:error, :invalid_old_password}

      Crypto.verify_password(old_password, user.password_hash) ->
        do_update_password(user, attrs)

      true ->
        {:error, :invalid_old_password}
    end
  end

  defp do_update_password(user, attrs) do
    user
    |> password_changeset(attrs)
    |> update_with_audit()
  end

  @doc """
  Stores an avatar for the given user.
  """
  @spec store_avatar(%User{}, map()) :: %User{} | Ecto.Changeset.t()
  def store_avatar(%User{} = user, attrs) do
    updated_attrs =
      case attrs["avatar"] do
        "" -> %{avatar: nil}
        "null" -> %{avatar: nil}
        avatar -> %{avatar: avatar}
      end

    updated_attrs = Map.put(updated_attrs, :originator, attrs["originator"])

    user
    |> avatar_changeset(updated_attrs)
    |> update_with_audit()
  end

  defp update_with_audit(changeset) do
    changeset
    |> Audit.update_record_with_audit()
    |> case do
      {:ok, result} ->
        {:ok, get(result.record.id)}

      {:error, _failed_operation, changeset, _changes_so_far} ->
        {:error, changeset}
    end
  end

  @doc """
  Retrieve the primary wallet for a user.
  """
  @spec get_primary_wallet(%User{}) :: %Wallet{} | nil
  def get_primary_wallet(user) do
    Wallet
    |> where([b], b.user_uuid == ^user.uuid)
    |> where([b], b.identifier == ^Wallet.primary())
    |> Repo.one()
  end

  @doc """
  Retrieve the primary wallet for a user with preloaded wallets.
  """
  @spec get_preloaded_primary_wallet(%User{}) :: %Wallet{} | nil
  def get_preloaded_primary_wallet(user) do
    Enum.find(user.wallets, fn wallet -> wallet.identifier == Wallet.primary() end)
  end

  @spec get_all_linked_accounts(String.t()) :: [%Account{}]
  def get_all_linked_accounts(user_uuid) do
    Repo.all(
      from(
        account in Account,
        join: account_user in AccountUser,
        on: account_user.account_uuid == account.uuid,
        where: account_user.user_uuid == ^user_uuid
      )
    )
  end

  @doc """
  Retrieves the status of the given user.
  """
  @spec get_status(%User{}) :: :active | :pending_confirmation
  def get_status(user) do
    if user.invite_uuid == nil, do: :active, else: :pending_confirmation
  end

  @doc """
  Retrieves the user's invite if any.
  """
  @spec get_invite(%User{}) :: %Invite{} | nil
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
  @spec has_membership?(%User{} | String.t()) :: boolean()
  def has_membership?(user) when is_binary(user) do
    query = from(m in Membership, where: m.user_uuid == ^user)
    Repo.aggregate(query, :count, :uuid) > 0
  end

  def has_membership?(%User{uuid: nil}), do: false

  def has_membership?(user) do
    query = from(m in Membership, where: m.user_uuid == ^user.uuid)
    Repo.aggregate(query, :count, :uuid) > 0
  end

  @doc """
  Checks if the user is assigned to the given role, regardless of which account.
  """
  @spec has_role?(%User{}, String.t()) :: boolean()
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
  @spec get_roles(%User{}) :: [String.t()]
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
  @spec get_role(String.t(), String.t()) :: String.t() | nil
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
  Sets the user's admin status.
  """
  @spec set_admin(%User{}, boolean()) :: {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def set_admin(user, boolean) do
    user
    |> change(is_admin: boolean)
    |> Repo.update()
  end

  @doc """
  Checks if the user is an admin user.
  """
  @spec admin?(String.t() | %User{}) :: boolean()
  def admin?(user), do: user.is_admin == true

  @doc """
  Checks if the user is an admin on the top-level account.
  """
  @spec master_admin?(%User{} | String.t()) :: boolean()
  def master_admin?(%User{id: user_id}) do
    master_admin?(user_id)
  end

  def master_admin?(user_id) do
    User.get_role(user_id, Account.get_master_account().id) == "admin"
  end

  @doc """
  Retrieves the upper-most account that the given user has membership in.
  """
  @spec get_account(%User{}) :: %Account{} | nil
  def get_account(user) do
    query =
      from(
        [q, child] in query_accounts(user),
        order_by: [asc: child.depth, desc: child.inserted_at],
        limit: 1
      )

    Repo.one(query)
  end

  @spec get_all_accessible_account_uuids(%User{}) :: [String.t()] | no_return()
  def get_all_accessible_account_uuids(user) do
    user
    |> get_membership_account_uuids()
    |> Account.get_all_descendants_uuids()
  end

  @doc """
  Retrieves the list of accounts that the given user has membership, including their child accounts.
  """
  @spec get_accounts(%User{}) :: [%Account{}]
  def get_accounts(user) do
    user
    |> query_accounts()
    |> Repo.all()
  end

  @spec get_membership_account_uuids(%User{}) :: [String.t()] | no_return()
  def get_membership_account_uuids(user) do
    user
    |> Membership.all_by_user()
    |> Enum.map(fn m -> Map.fetch!(m, :account_uuid) end)
  end

  @doc """
  Query the list of accounts that the given user has membership, including their child accounts.
  """
  @spec query_accounts(%User{}) :: Ecto.Queryable.t()
  def query_accounts(user) do
    account_uuids = get_membership_account_uuids(user)

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
