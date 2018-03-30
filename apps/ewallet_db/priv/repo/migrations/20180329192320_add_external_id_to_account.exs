defmodule EWalletDB.Repo.Migrations.AddExternalIdToAccount do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo
  alias ExULID.ULID

  def up do
    alter table(:account) do
      add :external_id, :string
    end

    create index(:account, [:external_id])

    flush()
    populate_external_id()
  end

  def down do
    alter table(:account) do
      remove :external_id
    end
  end

  defp populate_external_id do
    query = from(a in "account",
                 select: [a.id, a.inserted_at],
                 lock: "FOR UPDATE")

    for [id, inserted_at] <- Repo.all(query) do
      {date, {hours, minutes, seconds, microseconds}} = inserted_at

      {:ok, datetime} = NaiveDateTime.from_erl({date, {hours, minutes, seconds}}, {microseconds, 4})
      {:ok, datetime} = DateTime.from_naive(datetime, "Etc/UTC")

      ulid =
        datetime
        |> DateTime.to_unix(:millisecond)
        |> ULID.generate()

      query = from(a in "account",
                  where: a.id == ^id,
                  update: [set: [external_id: ^ulid]])

      Repo.update_all(query, [])
    end
  end
end
