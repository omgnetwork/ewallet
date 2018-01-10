defmodule KuberaDB.Role do
  @moduledoc """
  Ecto Schema representing user roles.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias KuberaDB.{Repo, Membership, Role, User}

  @primary_key {:id, UUID, autogenerate: true}

  schema "role" do
    field :name, :string
    field :display_name, :string
    many_to_many :users, User, join_through: Membership

    timestamps()
  end

  defp changeset(%Role{} = key, attrs) do
    key
    |> cast(attrs, [:name, :display_name])
    |> validate_required(:name)
    |> unique_constraint(:name)
  end

  @doc """
  Creates a new role with the passed attributes.
  """
  def insert(attrs) do
    %Role{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Retrieves a role by its string or atom name.
  """
  def get_by_name(nil), do: nil
  def get_by_name(name) when is_atom(name) do
    name
    |> Atom.to_string()
    |> get_by_name()
  end
  def get_by_name(name) when is_binary(name) do
    Repo.get_by(Role, name: name)
  end

  @doc """
  Compares that the given atom is equivalent to the given role.
  """
  def is_role?(%Role{} = role, role_atom) when is_atom(role_atom) do
    to_atom(role) == role_atom
  end

  @doc """
  Get the atom representation of the given role.
  """
  def to_atom(%Role{} = role) do
    role
    |> Map.get(:name)
    |> String.to_atom()
  end
end
