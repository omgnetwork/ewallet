defmodule KuberaDB.User do
  @moduledoc """
  Ecto Schema representing users.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  import KuberaDB.Validator
  alias Ecto.{Multi, UUID}
  alias KuberaDB.{Repo, AuthToken, Balance, User}
  alias KuberaDB.Helpers.Crypto

  @primary_key {:id, UUID, autogenerate: true}

  schema "user" do
    field :username, :string
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :provider_user_id, :string
    field :metadata, Cloak.EncryptedMapField
    field :encryption_version, :binary
    has_many :balances, Balance
    has_many :auth_tokens, AuthToken

    timestamps()
  end

  defp changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password, :provider_user_id, :metadata])
    |> validate_required([:username, :provider_user_id, :metadata])
    |> validate_immutable(:provider_user_id)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> unique_constraint(:provider_user_id)
    |> put_change(:password_hash, Crypto.hash_password(attrs[:password]))
    |> put_change(:encryption_version, Cloak.version)
  end

  @doc """
  Retrieves a specific user.
  """
  def get(id) do
    User
    |> Repo.get(id)
    |> Repo.preload(:balances)
  end

  @doc """
  Retrieves a specific user from its provider_user_id.
  """
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
      identifier: identifier,
      metadata: %{}
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
end
