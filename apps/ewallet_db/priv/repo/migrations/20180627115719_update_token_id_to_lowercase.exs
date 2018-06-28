defmodule EWalletDB.Repo.Migrations.UpdateTokenIdToLowercase do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  @table "token"

  def up do
    query = from(t in @table,
                 select: [t.uuid, t.id],
                 lock: "FOR UPDATE")

    for [uuid, id] <- Repo.all(query) do
      [prefix, symbol, ulid] = String.split(id, "_", parts: 3)
      new_id = prefix <> "_" <> symbol <> "_" <> String.downcase(ulid)

      query = from(t in @table,
                   where: t.uuid == ^uuid,
                   update: [set: [id: ^new_id]])

      Repo.update_all(query, [])
    end
  end

  def down do
    # Not converting the uppercase back because:
    # 1. We don't know which tokens had uppercases (tokens inserted before this migration),
    #    and which had lowercases (tokens created after this migration).
    # 2. The lowercased ID should still work.
    # 3. `up/0` can be called again without breaking.
  end
end
