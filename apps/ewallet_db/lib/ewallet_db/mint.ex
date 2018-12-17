defmodule EWalletDB.Mint do
  @moduledoc """
  Ecto Schema representing mints.
  """
  use Ecto.Schema
  use Utils.Types.ExternalID
  use ActivityLogger.ActivityLogging
  import Ecto.{Query, Changeset}
  import EWalletDB.Helpers.Preloader
  alias Ecto.UUID
  alias EWalletDB.{Account, Mint, Repo, Token, Transaction}

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}

  schema "mint" do
    external_id(prefix: "mnt_")

    field(:description, :string)
    field(:amount, Utils.Types.Integer)
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
    activity_logging()
  end

  defp changeset(%Mint{} = mint, attrs) do
    mint
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [
        :description,
        :amount,
        :account_uuid,
        :token_uuid,
        :confirmed
      ],
      required: [:amount, :token_uuid]
    )
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
    |> cast_and_validate_required_for_activity_log(
      attrs,
      cast: [:transaction_uuid],
      required: [:transaction_uuid]
    )
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
    |> Utils.Types.Integer.load!()
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
    |> Repo.insert_record_with_activity_log()
  end

  @doc """
  Updates a mint with the provided attributes.
  """
  @spec update(mint :: %Mint{}, attrs :: map()) :: {:ok, %Mint{}} | {:error, Ecto.Changeset.t()}
  def update(%Mint{} = mint, attrs) do
    mint
    |> update_changeset(attrs)
    |> Repo.update_record_with_activity_log()
  end

  @doc """
  Confirms a mint.
  """
  def confirm(%Mint{confirmed: true} = mint, _), do: mint

  def confirm(%Mint{confirmed: false} = mint, originator) do
    {:ok, mint} =
      mint
      |> changeset(%{
        confirmed: true,
        originator: originator
      })
      |> Repo.update_record_with_activity_log()

    mint
  end
end
