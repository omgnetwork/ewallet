defmodule EWalletDB.Repo.Migrations.AddFullNameAndCallingNameToUser do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :full_name, :string
      add :calling_name, :string
    end
  end
end
