defmodule EWalletDB.Role do
  @moduledoc """
  Ecto Schema representing user roles.
  """
  use Ecto.Schema
  use EWalletConfig.Types.ExternalID
  use EWalletDB.SoftDelete
  use EWalletDB.Auditable
  import Ecto.{Changeset, Query}
  import EWalletDB.Helpers.Preloader
  alias Ecto.UUID
  alias EWalletDB.{Membership, Repo, Role, User}

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "role" do
    external_id(prefix: "rol_")

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
    soft_delete()
    auditable()
  end

  defp changeset(%Role{} = key, attrs) do
    key
    |> cast(attrs, [:priority, :name, :display_name])
    |> validate_required([:name, :priority])
    |> unique_constraint(:name)
  end

  @doc """
  Get all roles.
  """
  @spec all(keyword()) :: [%__MODULE__{}] | []
  def all(opts \\ []) do
    __MODULE__
    |> Repo.all()
    |> preload_option(opts)
  end

  @doc """
  Retrieves a role with the given ID.
  """
  @spec get(String.t(), keyword()) :: %__MODULE__{} | nil
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

  @doc """
  Retrieves a role using one or more fields.
  """
  @spec get_by(map() | keyword(), keyword()) :: %__MODULE__{} | nil
  def get_by(fields, opts \\ []) do
    __MODULE__
    |> exclude_deleted()
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Creates a new role with the passed attributes.
  """
  def insert(attrs) do
    highest_priority = Repo.one(from(r in Role, select: max(r.priority)))

    [{key, _}] = Enum.take(attrs, 1)
    priority_field = if is_atom(key), do: :priority, else: "priority"

    attrs =
      case highest_priority do
        nil ->
          Map.put(attrs, priority_field, 0)

        highest_priority ->
          Map.put(attrs, priority_field, highest_priority + 1)
      end

    %Role{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a role with the passed attributes.
  """
  @spec update(%__MODULE__{}, map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(role, attrs) do
    role
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Checks whether the given role is soft-deleted.
  """
  @spec deleted?(%__MODULE__{}) :: boolean()
  def deleted?(role), do: SoftDelete.deleted?(role)

  @doc """
  Soft-deletes the given role. The operation fails if the role
  has one more more users associated.
  """
  @spec delete(%__MODULE__{}) ::
          {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()} | {:error, atom()}
  def delete(role) do
    empty? =
      role
      |> Repo.preload(:users)
      |> Map.get(:users)
      |> Enum.empty?()

    case empty? do
      true -> SoftDelete.delete(role)
      false -> {:error, :role_not_empty}
    end
  end

  @doc """
  Restores the given role from soft-delete.
  """
  @spec restore(%__MODULE__{}) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def restore(role), do: SoftDelete.restore(role)

  @doc """
  Compares that the given string value is equivalent to the given role.
  """
  def is_role?(%Role{} = role, role_name) do
    role.name == role_name
  end
end
