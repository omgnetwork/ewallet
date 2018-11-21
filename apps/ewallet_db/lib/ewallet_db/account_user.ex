defmodule EWalletDB.AccountUser do
  @moduledoc """
  Ecto Schema representing the relation between an account and a user.
  """
  use Ecto.Schema
  use Arc.Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias EWalletDB.{Audit, Account, AccountUser, User}

  alias EWalletConfig.Types.VirtualStruct

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "account_user" do
    field(:originator, VirtualStruct, virtual: true)

    belongs_to(
      :account,
      Account,
      foreign_key: :account_uuid,
      references: :uuid,
      type: UUID
    )

    belongs_to(
      :user,
      User,
      foreign_key: :user_uuid,
      references: :uuid,
      type: UUID
    )

    timestamps()
  end

  @spec changeset(account :: %AccountUser{}, attrs :: map()) :: Ecto.Changeset.t()
  defp changeset(%AccountUser{} = account, attrs) do
    account
    |> cast(attrs, [:account_uuid, :user_uuid, :originator])
    |> validate_required([:account_uuid, :user_uuid, :originator])
    |> unique_constraint(:account_uuid, name: :account_user_account_uuid_user_uuid_index)
    |> assoc_constraint(:account)
    |> assoc_constraint(:user)
  end

  @spec insert(attrs :: map()) :: {:ok, %AccountUser{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    opts = [on_conflict: :nothing]

    %AccountUser{}
    |> changeset(attrs)
    |> Audit.insert_record_with_audit(opts)
    |> case do
      {:ok, result} ->
        {:ok, result.record}

      error ->
        error
    end
  end

  def link(account_uuid, user_uuid, originator) do
    insert(%{
      account_uuid: account_uuid,
      user_uuid: user_uuid,
      originator: originator
    })
  end
end
