defmodule EWalletDB.Category do
  @moduledoc """
  Ecto Schema representing an account category.
  """
  use Ecto.Schema
  use EWalletDB.SoftDelete
  use EWalletDB.Types.ExternalID
  import Ecto.Changeset
  import EWalletDB.Helpers.Preloader
  alias Ecto.UUID
  alias EWalletDB.{Repo, Account}

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "category" do
    external_id(prefix: "cat_")

    field(:name, :string)
    field(:description, :string)
    timestamps()
    soft_delete()

    many_to_many(
      :accounts,
      Account,
      join_through: "account_category",
      join_keys: [category_uuid: :uuid, account_uuid: :uuid]
    )
  end

  defp changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :description])
    |> validate_required(:name)
    |> unique_constraint(:name)
  end

  @doc """
  Get all account categories.
  """
  @spec all(keyword()) :: [%__MODULE__{}] | []
  def all(opts \\ []) do
    __MODULE__
    |> Repo.all()
    |> preload_option(opts)
  end

  @doc """
  Retrieves an account category with the given ID.
  """
  @spec get(ExternalID.t(), keyword()) :: %__MODULE__{} | nil
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

  @doc """
  Retrieves an account category using one or more fields.
  """
  @spec get_by(map(), keyword()) :: %__MODULE__{} | nil
  def get_by(fields, opts \\ []) do
    __MODULE__
    |> exclude_deleted()
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Creates a new account category with the passed attributes.
  """
  @spec insert(map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an account category with the passed attributes.
  """
  @spec update(%__MODULE__{}, map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(category, attrs) do
    category
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Checks whether the given account category is soft-deleted.
  """
  def deleted?(category), do: SoftDelete.deleted?(category)

  @doc """
  Soft-deletes the given account category.
  """
  def delete(category), do: SoftDelete.delete(category)

  @doc """
  Restores the given account category from soft-delete.
  """
  def restore(category), do: SoftDelete.restore(category)
end
