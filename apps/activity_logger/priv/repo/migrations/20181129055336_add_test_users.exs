defmodule ActivityLogger.Repo.Migrations.AddTestUsers do
  use Ecto.Migration

  def change do
    if Mix.env == :test do
      create table(:test_user, primary_key: false) do
        add :uuid, :uuid, primary_key: true
        add :id, :string, null: false
        add :username, :string

        timestamps()
      end
    end
  end
end
