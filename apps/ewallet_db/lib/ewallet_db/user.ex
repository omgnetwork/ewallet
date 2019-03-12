# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWalletDB.User do
  @moduledoc """
  Ecto Schema representing users.
  """
  use Arc.Ecto.Schema
  use Ecto.Schema
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.Helpers.Preloader
  import EWalletDB.Validator
  alias Ecto.{Multi, UUID}
  alias Utils.Helpers.Crypto

  alias EWalletDB.{
    Account,
    AccountUser,
    AuthToken,
    Invite,
    Membership,
    Repo,
    GlobalRole,
    Role,
    User,
    Wallet
  }

  @primary_key {:uuid, UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  schema "user" do
    external_id(prefix: "usr_")

    field(:is_admin, :boolean, default: false)
    field(:global_role, :string)
    field(:username, :string)
    field(:full_name, :string)
    field(:calling_name, :string)
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, :string)
    field(:provider_user_id, :string)
    field(:metadata, :map, default: %{})
    field(:encrypted_metadata, EWalletDB.Encrypted.Map, default: %{})
    field(:avatar, EWalletDB.Uploaders.Avatar.Type)
    field(:enabled, :boolean, default: true)

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

    has_many(
      :account_links,
      AccountUser,
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

    many_to_many(
      :linked_accounts,
      Account,
      join_through: AccountUser,
      join_keys: [user_uuid: :uuid, account_uuid: :uuid]
    )

    timestamps()
    activity_logging()
  end

  defp changeset(changeset, attrs) do
    password_hash = attrs |> get_attr(:password) |> Crypto.hash_password()

    changeset
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
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
        :global_role
      ],
      encrypted: [
        :encrypted_metadata
      ],
      prevent_saving: [
        :password,
        :password_confirmation
      ]
    )
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_inclusion(:global_role, GlobalRole.global_roles())
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
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :username,
        :full_name,
        :calling_name,
        :provider_user_id,
        :metadata,
        :encrypted_metadata,
        :invite_uuid
      ],
      encrypted: [
        :encrypted_metadata
      ]
    )
    |> validate_immutable(:provider_user_id)
    |> unique_constraint(:username)
    |> unique_constraint(:provider_user_id)
    |> assoc_constraint(:invite)
    |> validate_by_roles(attrs)
  end

  defp update_admin_changeset(user, attrs) do
    user
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :full_name,
        :calling_name,
        :metadata,
        :encrypted_metadata,
        :invite_uuid,
        :global_role
      ],
      encrypted: [
        :encrypted_metadata
      ]
    )
    |> assoc_constraint(:invite)
    |> validate_by_roles(attrs)
  end

  defp set_admin_changeset(user, attrs) do
    cast_and_validate_required_for_activity_log(user, attrs, cast: [:is_admin])
  end

  defp avatar_changeset(user, attrs) do
    user
    |> cast_and_validate_required_for_activity_log(attrs, [])
    |> cast_attachments(attrs, [:avatar])
  end

  defp password_changeset(user, attrs) do
    password_hash = attrs |> get_attr(:password) |> Crypto.hash_password()

    user
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :password,
        :password_confirmation
      ],
      prevent_saving: [
        :password,
        :password_confirmation
      ]
    )
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(:password)
    |> put_change(:password_hash, password_hash)
  end

  defp enable_changeset(%User{} = user, attrs) do
    cast_and_validate_required_for_activity_log(
      user,
      attrs,
      cast: [:enabled],
      required: [:enabled]
    )
  end

  defp get_attr(attrs, atom_field) do
    attrs[atom_field] || attrs[Atom.to_string(atom_field)]
  end

  defp email_changeset(user, attrs) do
    user
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:email],
      required: [:email]
    )
    |> validate_email(:email)
    |> unique_constraint(:email)
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
    |> put_change(:global_role, GlobalRole.end_user())
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

  def query_admin_users(query \\ User) do
    where(query, [u], u.is_admin == true)
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
  Retrieves a specific admin.
  """
  @spec get_admin(String.t()) :: %User{} | nil
  @spec get_admin(String.t(), Ecto.Queryable.t()) :: %User{} | nil
  def get_admin(id, queryable \\ User)

  def get_admin(id, queryable) when is_external_id(id) do
    queryable
    |> Repo.get_by(id: id, is_admin: true)
    |> Repo.preload(:wallets)
  end

  def get_admin(_, _), do: nil

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
    |> Repo.insert_record_with_activity_log(
      [],
      Multi.run(Multi.new(), :wallet, fn _repo, %{record: record} ->
        case User.admin?(record) do
          true -> {:ok, nil}
          false -> insert_wallet(record, Wallet.primary())
        end
      end)
    )
    |> case do
      {:ok, user} ->
        {:ok, Repo.preload(user, [:wallets])}

      error ->
        error
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
      identifier: identifier,
      originator: user
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

    Repo.update_record_with_activity_log(changeset)
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
    |> Repo.update_record_with_activity_log()
  end

  @doc """
  Updates a user's email with the provided attributes.
  """
  @spec update_email(%User{}, map()) :: {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def update_email(%User{} = user, attrs) do
    user
    |> email_changeset(attrs)
    |> Repo.update_record_with_activity_log()
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
    |> Repo.update_record_with_activity_log()
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
  """
  @spec get_role(String.t(), %Account{}) :: String.t() | nil
  def get_role(user, account) do
    case Membership.get_by_member_and_account(user, account) do
      nil ->
        nil

      membership ->
        membership.role.name
    end
  end

  @doc """
  Sets the user's admin status.
  """
  @spec set_admin(%User{}, boolean(), map()) :: {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def set_admin(user, boolean, originator) do
    user
    |> set_admin_changeset(%{
      is_admin: boolean,
      originator: originator
    })
    |> Repo.update_record_with_activity_log()
  end

  @doc """
  Checks if the user is an admin user.
  """
  @spec admin?(String.t() | %User{}) :: boolean()
  def admin?(user), do: user.is_admin == true

  @doc """
  Checks if the user is enabled.
  """
  @spec enabled?(String.t() | %User{}) :: boolean()
  def enabled?(user), do: user.enabled == true

  @doc """
  Retrieves the list of accounts that the given user has membership.
  """
  @spec get_accounts(%User{}) :: [%Account{}]
  def get_accounts(user) do
    Repo.preload(user, [:accounts]).accounts
  end

  @doc """
  Returns a random account from the user.
  """
  @spec get_account(%User{}) :: [%Account{}]
  def get_account(user) do
    user
    |> Ecto.assoc(:accounts)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Enables or disables a user.
  """
  def enable_or_disable(user, attrs) do
    user
    |> enable_changeset(attrs)
    |> Repo.update_record_with_activity_log()
  end
end
