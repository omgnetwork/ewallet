defmodule EWalletDB.Repo.Migrations.RenameConsumptionTimestampColumns do
  use Ecto.Migration

  def up do
    rename table(:transaction_consumption), :finalized_at, to: :approved_at

    alter table(:transaction_consumption) do
      add :confirmed_at, :naive_datetime
      add :rejected_at, :naive_datetime
      add :failed_at, :naive_datetime
      remove :approved
    end
  end

  def down do
    rename table(:transaction_consumption), :approved_at, to: :finalized_at

    alter table(:transaction_consumption) do
      remove :confirmed_at
      remove :rejected_at
      remove :failed_at
      add :approved, :boolean
    end
  end
end
