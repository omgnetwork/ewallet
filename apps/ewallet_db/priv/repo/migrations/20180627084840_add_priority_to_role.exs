defmodule EWalletDB.Repo.Migrations.AddPriorityToRole do
  use Ecto.Migration
  alias EWalletDB.Repo

  def change do
    alter table(:role) do
      add :priority, :integer
    end
    create unique_index(:role, [:priority])

    flush()

    {:ok, res} = Repo.query("SELECT uuid FROM role ORDER BY inserted_at")

    res.rows
    |> Enum.with_index
    |> Enum.each(fn({row, i}) ->
      {:ok, _} = Repo.query("UPDATE role SET priority = $1 WHERE uuid = $2", [i, Enum.at(row, 0)])
    end)

    flush()

    alter table(:role) do
      modify :priority, :integer, null: false
    end
  end
end
