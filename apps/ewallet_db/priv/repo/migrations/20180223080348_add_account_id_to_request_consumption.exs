defmodule EWalletDB.Repo.Migrations.AddAccountIDToRequestConsumption do
  use Ecto.Migration

    def up do
      alter table(:transaction_request_consumption) do
        add :account_id, references(:account, type: :uuid)
      end
    end

    def down do
      alter table(:transaction_request_consumption) do
        remove :account_id
      end
    end
end
