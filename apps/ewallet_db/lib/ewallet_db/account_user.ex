defmodule EWalletDB.AccountUser do
  @moduledoc """
  Ecto Schema representing the relation between an account and a user.
  """
  use Ecto.Schema
  use Arc.Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID
  alias EWalletDB.{Repo, AccountUser, Account, User}

  @primary_key {:uuid, UUID, autogenerate: true}

  schema "account_user" do
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
    |> cast(attrs, [:account_uuid, :user_uuid])
    |> validate_required([:account_uuid, :user_uuid])
    |> unique_constraint(:account_uuid, name: :account_user_account_uuid_user_uuid_index)
    |> assoc_constraint(:account)
    |> assoc_constraint(:user)
  end

  @spec insert(attrs :: map()) :: {:ok, %AccountUser{}} | {:error, Ecto.Changeset.t()}
  def insert(attrs) do
    opts = [on_conflict: :nothing]

    %AccountUser{}
    |> changeset(attrs)
    |> Repo.insert(opts)
  end

  def link(account_uuid, user_uuid) do
    insert(%{
      account_uuid: account_uuid,
      user_uuid: user_uuid
    })
  end
end
