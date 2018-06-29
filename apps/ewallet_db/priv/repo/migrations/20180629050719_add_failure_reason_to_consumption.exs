defmodule EWalletDB.Repo.Migrations.AddFailureReasonToConsumption do
  use Ecto.Migration

  def change do
    alter table(:transaction_consumption) do
      add :error_code, :string
      add :error_description, :string
    end
  end
end
