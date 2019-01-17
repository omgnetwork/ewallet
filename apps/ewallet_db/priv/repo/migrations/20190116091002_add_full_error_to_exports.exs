defmodule EWalletDB.Repo.Migrations.AddFullErrorToExports do
  use Ecto.Migration

  def change do
    alter table(:export) do
      add :full_error, :text
    end
  end
end
