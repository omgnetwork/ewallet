defmodule ActivityLogger.Repo.Migrations.AddTestDocumentTable do
  use Ecto.Migration

  def change do
    if Mix.env == :test do
      create table(:test_document, primary_key: false) do
        add :uuid, :uuid, primary_key: true
        add :id, :string, null: false
        add :title, :string
        add :body, :string
        add :secret_data, :binary

        timestamps()
      end
    end
  end
end
