defmodule EWalletDB.Repo.Migrations.AddGlobalRolesToUserAndKey do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :global_role, :string
    end

    alter table(:key) do
      add :global_role, :string
    end
  end
end
