defmodule EWalletDB.ExchangePair do
  @moduledoc """
  Ecto Schema representing an exchange pair.

  # What is an exchange rate?

  The exchange rate is the amount of the destination token (`to_token`) that will be received
  when exchanged with one unit of the source token (`from_token`).

  For example:

  ```
  %EWalletDB.ExchangePair{
    name: "AAA/BBB",
    from_token: AAA,
    to_token: BBB,
    rate: 2.00
  }
  ```

  The struct above means that 1 AAA can be exchanged for 2 AAA.
  """
  use Ecto.Schema
  use EWalletDB.SoftDelete
  use EWalletDB.Types.ExternalID
  import Ecto.Changeset
  import EWalletDB.Helpers.Preloader
  alias Ecto.UUID
  alias EWalletDB.{Repo, Token}

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "exchange_pair" do
    external_id(prefix: "exg_")

    field(:name, :string)
    field(:rate, :float)

    belongs_to(
      :from_token,
      Token,
      references: :uuid,
      type: UUID,
      foreign_key: :from_token_uuid
    )

    belongs_to(
      :to_token,
      Token,
      references: :uuid,
      type: UUID,
      foreign_key: :to_token_uuid
    )

    timestamps()
    soft_delete()
  end

  defp changeset(exchange_pair, attrs) do
    exchange_pair
    |> cast(attrs, [:name, :from_token_uuid, :to_token_uuid, :rate])
    |> validate_required([:name, :rate])
    |> validate_number(:rate, greater_than: 0)
    |> assoc_constraint(:from_token)
    |> assoc_constraint(:to_token)
    |> unique_constraint(:name)
    |> unique_constraint(
      :from_token,
      name: "exchange_pair_from_token_uuid_to_token_uuid_deleted_at_index"
    )
  end

  defp update_changeset(exchange_pair, attrs) do
    exchange_pair
    |> cast(attrs, [:name, :rate])
    |> validate_required([:name, :rate])
    |> unique_constraint(:name)
    |> unique_constraint(
      :from_token,
      name: "exchange_pair_from_token_uuid_to_token_uuid_deleted_at_index"
    )
  end

  @doc """
  Get all exchange pairs.
  """
  @spec all(keyword()) :: [%__MODULE__{}] | []
  def all(opts \\ []) do
    __MODULE__
    |> exclude_deleted()
    |> Repo.all()
    |> preload_option(opts)
  end

  @doc """
  Retrieves an exchange pair with the given ID.
  """
  @spec get(ExternalID.t(), keyword()) :: %__MODULE__{} | nil
  def get(id, opts \\ [])

  def get(id, opts) when is_external_id(id) do
    get_by([id: id], opts)
  end

  def get(_id, _opts), do: nil

  @doc """
  Retrieves an exchange pair using one or more fields.
  """
  @spec get_by(map() | keyword(), keyword()) :: %__MODULE__{} | nil
  def get_by(fields, opts \\ []) do
    __MODULE__
    |> exclude_deleted()
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Creates a new exchange pair with the passed attributes.
  """
  @spec insert(map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an exchange pair with the passed attributes.
  """
  @spec update(%__MODULE__{}, map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def update(exchange_pair, attrs) do
    exchange_pair
    |> update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Checks whether the given exchange pair is soft-deleted.
  """
  @spec deleted?(%__MODULE__{}) :: boolean()
  def deleted?(exchange_pair), do: SoftDelete.deleted?(exchange_pair)

  @doc """
  Soft-deletes the given exchange pair.
  """
  @spec delete(%__MODULE__{}) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def delete(exchange_pair), do: SoftDelete.delete(exchange_pair)

  @doc """
  Restores the given exchange pair from soft-delete.
  """
  @spec restore(%__MODULE__{}) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def restore(exchange_pair), do: SoftDelete.restore(exchange_pair)

  @doc """
  Retrieves an exchange pair using `from_token` and `to_token`.

  If an exchange pair is found, `{:ok, pair}` is returned.
  If an exchange pair could not be found, `{:error, :exchange_pair_not_found}` is returned.
  """
  @spec fetch_exchangable_pair(%Token{}, %Token{}, keyword()) ::
          {:ok, %__MODULE__{}} | {:error, :exchange_pair_not_found}
  def fetch_exchangable_pair(%{uuid: from}, %{uuid: to}, opts \\ []) do
    case get_by([from_token_uuid: from, to_token_uuid: to], opts) do
      %__MODULE__{} = pair ->
        {:ok, pair}

      nil ->
        {:error, :exchange_pair_not_found}
    end
  end
end
