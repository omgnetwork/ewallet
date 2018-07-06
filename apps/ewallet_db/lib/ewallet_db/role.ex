defmodule EWalletDB.Role do
  @moduledoc """
  Ecto Schema representing user roles.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias Ecto.UUID
  alias EWalletDB.{Repo, Membership, Role, User}

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "role" do
    field(:name, :string)
    field(:priority, :integer)
    field(:display_name, :string)

    many_to_many(
      :users,
      User,
      join_through: Membership,
      join_keys: [role_uuid: :uuid, user_uuid: :uuid]
    )

    timestamps()
  end

  defp changeset(%Role{} = key, attrs) do
    key
    |> cast(attrs, [:priority, :name, :display_name])
    |> validate_required([:name, :priority])
    |> unique_constraint(:name)
  end

  @doc """
  Creates a new role with the passed attributes.
  """
  def insert(attrs) do
    highest_priority = Repo.one(from(r in Role, select: max(r.priority)))

    attrs =
      case highest_priority do
        nil ->
          Map.put(attrs, :priority, 0)

        highest_priority ->
          Map.put(attrs, :priority, highest_priority + 1)
      end

    %Role{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Retrieves a role by its string name.
  """
  def get_by_name(name) when is_binary(name) do
    Repo.get_by(Role, name: name)
  end

  def get_by_name(_), do: nil

  @doc """
  Compares that the given string value is equivalent to the given role.
  """
  def is_role?(%Role{} = role, role_name) do
    role.name == role_name
  end
end
