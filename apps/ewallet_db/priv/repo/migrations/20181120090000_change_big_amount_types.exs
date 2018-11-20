defmodule EWalletDB.Repo.Migrations.ChangeBigAmountTypes do
  use Ecto.Migration

  def up do
    alter table(:token) do
      modify :subunit_to_unit, :decimal, precision: nil, scale: 0, null: false
    end

    alter table(:mint) do
      modify :amount, :decimal, precision: nil, scale: 0, null: false
    end

    alter table(:transaction) do
      modify :from_amount, :decimal, precision: nil, scale: 0, null: false
      modify :to_amount, :decimal, precision: nil, scale: 0, null: false
    end

    alter table(:transaction_request) do
      modify :amount, :decimal, precision: nil, scale: 0
    end

    alter table(:transaction_consumption) do
      modify :amount, :decimal, precision: nil, scale: 0
      modify :estimated_request_amount, :decimal, precision: nil, scale: 0
      modify :estimated_consumption_amount, :decimal, precision: nil, scale: 0
    end
  end

  def down do
    alter table(:token) do
      modify :subunit_to_unit, :decimal, precision: 81, scale: 0, null: false
    end

    alter table(:mint) do
      modify :amount, :decimal, precision: 81, scale: 0, null: false
    end

    alter table(:transaction) do
      modify :from_amount, :decimal, precision: 81, scale: 0, null: false
      modify :to_amount, :decimal, precision: 81, scale: 0, null: false
    end

    alter table(:transaction_request) do
      modify :amount, :decimal, precision: 81, scale: 0
    end

    alter table(:transaction_consumption) do
      modify :amount, :decimal, precision: 81, scale: 0
      modify :estimated_request_amount, :decimal, precision: 81, scale: 0
      modify :estimated_consumption_amount, :decimal, precision: 81, scale: 0
    end
  end
end
