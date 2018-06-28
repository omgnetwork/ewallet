defmodule EWalletDB.Repo.Migrations.AddFromOwnerAndToOwnerToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transaction) do
      add :from_account_uuid, references(:account, column: :uuid, type: :uuid)
      add :from_user_uuid, references(:user, column: :uuid, type: :uuid)
      add :to_account_uuid, references(:account, column: :uuid, type: :uuid)
      add :to_user_uuid, references(:user, column: :uuid, type: :uuid)
    end

    create index(:transaction, [:from_account_uuid, :to_account_uuid])
    create index(:transaction, [:to_account_uuid])
    create index(:transaction, [:from_user_uuid, :to_user_uuid])
    create index(:transaction, [:to_user_uuid])
  end
end
