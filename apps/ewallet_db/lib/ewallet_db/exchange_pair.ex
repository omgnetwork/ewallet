defmodule EWalletDB.ExchangePair do
  @moduledoc """
  Ecto Schema representing an exchange pair.

  # What is an exchange rate?

  The exchange rate is the amount of the destination token (`to_token`) that will be received
  when exchanged with one unit of the source token (`from_token`).

  For example:

  ```
  %EWalletDB.ExchangePair{
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
  import EWalletDB.Validator
  alias Ecto.UUID
  alias EWalletDB.{Repo, Token}

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "exchange_pair" do
    external_id(prefix: "exg_")

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

    field(:rate, :float)
    timestamps()
    soft_delete()
  end

  defp changeset(exchange_pair, attrs) do
    exchange_pair
    |> cast(attrs, [:from_token_uuid, :to_token_uuid, :rate, :deleted_at])
    |> validate_required([:from_token_uuid, :to_token_uuid, :rate])
    |> validate_different_values(:from_token_uuid, :to_token_uuid)
    |> validate_immutable(:from_token_uuid)
    |> validate_immutable(:to_token_uuid)
    |> validate_number(:rate, greater_than: 0)
    |> assoc_constraint(:from_token)
    |> assoc_constraint(:to_token)
    |> unique_constraint(
      :from_token,
      name: "exchange_pair_from_token_uuid_to_token_uuid_index"
    )
  end

  defp restore_changeset(exchange_pair, attrs) do
    exchange_pair
    |> cast(attrs, [:deleted_at])
    |> unique_constraint(
      :deleted_at,
      name: "exchange_pair_from_token_uuid_to_token_uuid_index"
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
    |> changeset(attrs)
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
  def restore(exchange_pair) do
    changeset = restore_changeset(exchange_pair, %{deleted_at: nil})

    case Repo.update(changeset) do
      {:error, %{errors: [deleted_at: {"has already been taken", []}]}} ->
        {:error, :exchange_pair_already_exists}

      result ->
        result
    end
  end

  @doc """
  Touches the given exchange pair and updates `updated_at` to the current date & time.
  """
  @spec touch(%__MODULE__{}) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
  def touch(exchange_pair) do
    exchange_pair
    |> change(updated_at: NaiveDateTime.utc_now())
    |> Repo.update()
  end

  @doc """
  Gets the standard name of the exchange pair.
  """
  @spec get_name(%__MODULE__{}) :: String.t()
  def get_name(exchange_pair) do
    exchange_pair = Repo.preload(exchange_pair, [:from_token, :to_token])
    exchange_pair.from_token.symbol <> "/" <> exchange_pair.to_token.symbol
  end

  @doc """
  Retrieves an exchange pair using `from_token` and `to_token`.

  If an exchange pair is found, `{:ok, pair}` is returned.
  If an exchange pair could not be found, `{:error, :exchange_pair_not_found}` is returned.
  """
  @spec fetch_exchangable_pair(%Token{} | String.t(), %Token{} | String.t(), keyword()) ::
          {:ok, %__MODULE__{}} | {:error, :exchange_pair_not_found}
  def fetch_exchangable_pair(from, to, opts \\ [])

  def fetch_exchangable_pair(%Token{} = from_token, %Token{} = to_token, opts) do
    fetch_exchangable_pair(from_token.uuid, to_token.uuid, opts)
  end

  def fetch_exchangable_pair(from_token_uuid, to_token_uuid, opts) do
    case get_by([from_token_uuid: from_token_uuid, to_token_uuid: to_token_uuid], opts) do
      %__MODULE__{} = pair ->
        {:ok, pair}

      nil ->
        {:error, :exchange_pair_not_found}
    end
  end
end
