defmodule EWalletDB.Category do
  @moduledoc """
  Ecto Schema representing a category.
  """
  use Ecto.Schema
  use EWalletDB.SoftDelete
  use EWalletDB.Types.ExternalID
  import Ecto.{Changeset, Query}
  import EWalletDB.Helpers.Preloader
  alias Ecto.UUID
  alias EWalletDB.{Repo, Account}
  alias EWalletDB.Helpers.InputAttribute

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
      join_keys: [category_uuid: :uuid, account_uuid: :uuid],
      on_replace: :delete
    )
  end

  defp changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :description])
    |> validate_required(:name)
    |> unique_constraint(:name)
    |> put_accounts(attrs, :account_ids)
  end

  defp put_accounts(changeset, attrs, attr_name) do
    case InputAttribute.get(attrs, attr_name) do
      ids when is_list(ids) ->
        put_accounts(changeset, ids)
      _ ->
        changeset
    end
  end

  defp put_accounts(changeset, account_ids) do
    # Associations need to be preloaded before updating
    changeset = Map.put(changeset, :data, Repo.preload(changeset.data, :accounts))
    accounts = Repo.all(from(a in Account, where: a.id in ^account_ids))
    put_assoc(changeset, :accounts, accounts)
  end

  @doc """
  Get all categories.
  """
  @spec all(keyword()) :: [%__MODULE__{}] | []
  def all(opts \\ []) do
    __MODULE__
    |> Repo.all()
    |> preload_option(opts)
  end

  @doc """
  Retrieves a category with the given ID.
  """
  @spec get(ExternalID.t(), keyword()) :: %__MODULE__{} | nil
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

  @doc """
  Retrieves a category using one or more fields.
  """
  @spec get_by(map() | keyword(), keyword()) :: %__MODULE__{} | nil
  def get_by(fields, opts \\ []) do
    __MODULE__
    |> exclude_deleted()
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Creates a new category with the passed attributes.
  """
  @spec insert(map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category with the passed attributes.
  """
  @spec update(%__MODULE__{}, map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(category, attrs) do
    category
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Checks whether the given category is soft-deleted.
  """
  @spec deleted?(%__MODULE__{}) :: boolean()
  def deleted?(category), do: SoftDelete.deleted?(category)

  @doc """
  Soft-deletes the given category.
  """
  @spec delete(%__MODULE__{}) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def delete(category), do: SoftDelete.delete(category)

  @doc """
  Restores the given category from soft-delete.
  """
  @spec restore(%__MODULE__{}) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def restore(category), do: SoftDelete.restore(category)
end
