defmodule KuberaDB.User do
  @moduledoc """
  Ecto Schema representing users.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias KuberaDB.{Repo, User}

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "user" do
    field :username, :string
    field :provider_user_id, :string
    field :metadata, :map

    timestamps()
  end

  @doc """
  Validates user data.

  ## Examples

      iex> changeset(%User{}, %{field: value})
      %User{}

  """
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :provider_user_id, :metadata])
    |> validate_required([:username, :provider_user_id])
    |> unique_constraint(:username)
    |> unique_constraint(:provider_user_id)
  end

  @doc """
  Retrieves a specific user.

  ## Examples

      iex> get(123)
      %User{}

  """
  def get(id) do
    Repo.get(User, id)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> insert(%{field: value})
      {:ok, %User{}}

  """
  def insert(attrs) do
    changeset = User.changeset(%User{}, attrs)
    Repo.insert(changeset)
  end
end
