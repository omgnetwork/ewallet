defmodule EWalletDB.Repo.Migrations.AddSecret2faCodeToUser do
  use Ecto.Migration

  def change do
    alter table(:user) do
      add :secret_2fa_code, :string
    end
  end
end
