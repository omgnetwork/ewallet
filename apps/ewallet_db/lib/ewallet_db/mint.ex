defmodule EWalletDB.Mint do
  @moduledoc """
  Ecto Schema representing mints.
  """
  use Ecto.Schema
  use EWalletDB.Types.ExternalID
  import Ecto.{Query, Changeset}
  import EWalletDB.Helpers.Preloader
  alias Ecto.UUID
  alias EWalletDB.{Account, Mint, Repo, Token, Transaction}

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}

  schema "mint" do
    external_id(prefix: "mnt_")

    field(:description, :string)
    field(:amount, EWalletDB.Types.Integer)
    field(:confirmed, :boolean, default: false)

    belongs_to(
      :token,
      Token,
      foreign_key: :token_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :account,
      Account,
      foreign_key: :account_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :transaction,
      Transaction,
      foreign_key: :transaction_uuid,
      references: :uuid,
      type: UUID
    )

    timestamps()
  end

  defp changeset(%Mint{} = mint, attrs) do
    mint
    |> cast(attrs, [:description, :amount, :account_uuid, :token_uuid, :confirmed])
    |> validate_required([:amount, :token_uuid])
    |> validate_number(
      :amount,
      greater_than: 0,
      less_than: 100_000_000_000_000_000_000_000_000_000_000_000
    )
    |> assoc_constraint(:token)
    |> assoc_constraint(:account)
    |> assoc_constraint(:transaction)
    |> foreign_key_constraint(:token_uuid)
    |> foreign_key_constraint(:account_uuid)
    |> foreign_key_constraint(:transaction_uuid)
  end

  defp update_changeset(%Mint{} = mint, attrs) do
    mint
    |> cast(attrs, [:transaction_uuid])
    |> validate_required([:transaction_uuid])
    |> assoc_constraint(:transaction)
  end

  def query_by_token(token, query \\ Mint) do
    from(m in query, where: m.token_uuid == ^token.uuid)
  end

  def total_supply_for_token(token) do
    Mint
    |> where([m], m.token_uuid == ^token.uuid)
    |> select([m], sum(m.amount))
    |> Repo.one()
    |> EWalletDB.Types.Integer.load!()
  end

  @doc """
  Retrieve a mint by id.
  """
  @spec get_by(String.t(), opts :: keyword()) :: %Mint{} | nil
  def get(id, opts \\ [])
  def get(nil, _), do: nil

  def get(id, opts) do
    get_by([id: id], opts)
  end

  @doc """
  Retrieves a mint using one or more fields.
  """
  @spec get_by(fields :: map() | keyword(), opts :: keyword()) :: %Mint{} | nil
  def get_by(fields, opts \\ []) do
    Mint
    |> Repo.get_by(fields)
    |> preload_option(opts)
  end

  @doc """
  Create a new mint with the passed attributes.
  """
  def insert(attrs) do
    %Mint{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a mint with the provided attributes.
  """
  @spec update(mint :: %Mint{}, attrs :: map()) :: {:ok, %Mint{}} | {:error, Ecto.Changeset.t()}
  def update(%Mint{} = mint, attrs) do
    changeset = update_changeset(mint, attrs)

    case Repo.update(changeset) do
      {:ok, mint} ->
        {:ok, mint}

      result ->
        result
    end
  end

  @doc """
  Confirms a mint.
  """
  def confirm(%Mint{confirmed: true} = mint), do: mint

  def confirm(%Mint{confirmed: false} = mint) do
    {:ok, mint} =
      mint
      |> changeset(%{confirmed: true})
      |> Repo.update()

    mint
  end
end
