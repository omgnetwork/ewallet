defmodule EWalletDB.Mint do
  @moduledoc """
  Ecto Schema representing mints.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias EWalletDB.{Repo, Mint, MintedToken, Transfer, Account}

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "mint" do
    field :description, :string
    field :amount, EWalletDB.Types.Integer
    field :confirmed, :boolean, default: false
    belongs_to :minted_token, MintedToken, foreign_key: :minted_token_id,
                                           references: :id,
                                           type: UUID
    belongs_to :account, Account, foreign_key: :account_id,
                                  references: :id,
                                  type: UUID
    belongs_to :transfer, Transfer, foreign_key: :transfer_id,
                                    references: :id,
                                    type: UUID
    timestamps()
  end

  defp changeset(%Mint{} = minted_token, attrs) do
    minted_token
    |> cast(attrs, [:description, :amount, :minted_token_id, :confirmed])
    |> validate_required([:amount, :minted_token_id])
    |> validate_number(:amount, greater_than: 0)
    |> assoc_constraint(:minted_token)
  end

  defp update_changeset(%Mint{} = minted_token, attrs) do
    minted_token
    |> cast(attrs, [:transfer_id])
    |> validate_required([:transfer_id])
    |> assoc_constraint(:transfer)
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
  @spec update(mint :: %Mint{}, attrs :: map()) ::
    {:ok, %Mint{}} | {:error, Ecto.Changeset.t}
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
