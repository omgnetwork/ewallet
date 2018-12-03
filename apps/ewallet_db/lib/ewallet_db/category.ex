defmodule EWalletDB.Category do
  @moduledoc """
  Ecto Schema representing a category.
  """
  use Ecto.Schema
  use EWalletDB.SoftDelete
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import Ecto.{Changeset, Query}
  import EWalletDB.Helpers.Preloader
  alias Ecto.UUID
  alias Utils.Helpers.InputAttribute
  alias EWalletDB.{Account, Repo}

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "category" do
    external_id(prefix: "cat_")

    field(:name, :string)
    field(:description, :string)

    many_to_many(
      :accounts,
      Account,
      join_through: "account_category",
      join_keys: [category_uuid: :uuid, account_uuid: :uuid],
      on_replace: :delete
    )

    timestamps()
    soft_delete()
    activity_logging()
  end

  defp changeset(category, attrs) do
    category
    |> cast_and_validate_required_for_activity_log(
      attrs,
      [:name, :description],
      [:name]
    )
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
  @spec get(String.t(), keyword()) :: %__MODULE__{} | nil
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
    |> Repo.insert_record_with_activity_log()
  end

  @doc """
  Updates a category with the passed attributes.
  """
  @spec update(%__MODULE__{}, map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(category, attrs) do
    category
    |> changeset(attrs)
    |> Repo.update_record_with_activity_log()
  end

  @doc """
  Checks whether the given category is soft-deleted.
  """
  @spec deleted?(%__MODULE__{}) :: boolean()
  def deleted?(category), do: SoftDelete.deleted?(category)

  @doc """
  Soft-deletes the given category. The operation fails if the category
  has one more more accounts associated.
  """
  @spec delete(%__MODULE__{}, map()) ::
          {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()} | {:error, atom()}
  def delete(category, originator) do
    empty? =
      category
      |> Repo.preload(:accounts)
      |> Map.get(:accounts)
      |> Enum.empty?()

    case empty? do
      true -> SoftDelete.delete(category, originator)
      false -> {:error, :category_not_empty}
    end
  end

  @doc """
  Restores the given category from soft-delete.
  """
  @spec restore(%__MODULE__{}, map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def restore(category, originator), do: SoftDelete.restore(category, originator)
end
