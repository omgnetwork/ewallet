defmodule EWalletDB.Repo.Migrations.AddCrossTokenSupportToTransfers do
  use Ecto.Migration
  import Ecto.Query
  alias Ecto.MigrationError
  alias EWalletDB.Repo

  def up do
    _ = add_fields()
    _ = flush()
    _ = populate_fields()
    _ = turn_off_nullables()
    _ = remove_old_fields()
  end

  def add_fields do
    # Fields are added with `null:true` so we can populate data in.
    alter table(:transfer) do
      add :from_amount, :decimal, precision: 81,
                                  scale: 0,
                                  null: true

      add :from_token_uuid, references(:token, column: :uuid, type: :uuid), null: true

      add :to_amount, :decimal, precision: 81,
                                scale: 0,
                                null: true

      add :to_token_uuid, references(:token, column: :uuid, type: :uuid), null: true

      add :exchange_account_uuid, references(:account, column: :uuid, type: :uuid), null: true
    end
  end

  defp populate_fields do
    query = from(t in "transfer", update: [set: [from_amount: t.amount,
                                                 from_token_uuid: t.token_uuid,
                                                 to_amount: t.amount,
                                                 to_token_uuid: t.token_uuid]])

    _ = Repo.update_all(query, [])
  end

  defp turn_off_nullables do
    alter table(:transfer) do
      modify :from_amount, :decimal, null: false
      modify :from_token_uuid, :uuid, null: false
      modify :to_amount, :decimal, null: false
      modify :to_token_uuid, :uuid, null: false
    end
  end

  defp remove_old_fields do
    alter table(:transfer) do
      remove :amount
      remove :token_uuid
    end
  end

  def down do
    raise MigrationError, message: "This migration cannot be rolled back due to potential loss
                                   of transfer data."
  end
end
