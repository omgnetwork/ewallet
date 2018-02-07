defmodule EWalletDB.TransactionRequest do
  @moduledoc """
  Ecto Schema representing transaction requests.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias EWalletDB.{TransactionRequest, Repo, MintedToken, User, Balance, Helpers}

  @pending "pending"
  @confirmed "confirmed"
  @cancelled "cancelled"
  @statuses [@pending, @confirmed, @cancelled]

  @send    "send"
  @receive "receive"
  @types   [@send, @receive]

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "transaction_request" do
    field :type, :string
    field :amount, EWalletDB.Types.Integer
    field :status, :string, default: @pending # pending -> confirmed
    field :correlation_id, :string
    belongs_to :user, User, foreign_key: :user_id,
                                         references: :id,
                                         type: UUID
    belongs_to :minted_token, MintedToken, foreign_key: :minted_token_id,
                                           references: :id,
                                           type: UUID
    belongs_to :balance, Balance, foreign_key: :balance_address,
                                  references: :address,
                                  type: :string
    timestamps()
  end

  defp create_changeset(%TransactionRequest{} = transaction_request, attrs) do
    transaction_request
    |> cast(attrs, [
      :type, :amount, :correlation_id, :user_id, :minted_token_id, :balance_address
    ])
    |> validate_required([
      :type, :status, :user_id, :minted_token_id
    ])
    |> validate_inclusion(:type, @types)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint(:correlation_id)
    |> foreign_key_constraint(:minted_token_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:balance_address)
  end

  @doc """
  Gets a transaction request.
  """
  def get(nil), do: nil
  def get(id, opts \\ [preload: []])
  def get(nil, _), do: nil
  def get(id, opts) do
    case Helpers.UUID.valid?(id) do
      true ->
        TransactionRequest
        |> Repo.get(id)
        |> Repo.preload(opts[:preload])
      false -> nil
    end
  end

  @doc """
  Inserts a transaction request.
  """
  def insert(attrs) do
    %TransactionRequest{}
    |> create_changeset(attrs)
    |> Repo.insert()
  end
end
