defmodule KuberaDB.Repo.Migrations.AddFromAndToToTransfers do
  use Ecto.Migration

  def change do
    alter table(:transfer) do
      add :amount, :decimal, precision: 81, scale: 0, null: false
      add :minted_token_id, references(:minted_token, type: :uuid)
      add :from, references(:balance, type: :string,
                                      column: :address),
                                      null: false
      add :to, references(:balance, type: :string,
                                      column: :address),
                                      null: false
    end
  end
end
