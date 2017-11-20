defmodule KuberaDB.Repo.Migrations.AddFriendlyIDToMintedTokens do
  use Ecto.Migration
  import Ecto.Query
  alias KuberaDB.Repo

  def up do
    alter table(:minted_token) do
      add :friendly_id, :string
    end
    flush()

    query =
      from(m in "minted_token",
        select: [m.id, m.friendly_id, m.symbol],
        where: is_nil(m.friendly_id),
        lock: "FOR UPDATE")

    query
    |> Repo.all()
    |> migrate_friendly_ids()

    alter table(:minted_token) do
      modify :friendly_id, :string, null: false
    end

    create unique_index(:minted_token, [:friendly_id])
  end

  def down do
    alter table(:minted_token) do
      remove :friendly_id
    end
  end

  defp migrate_friendly_ids(minted_tokens) do
    for [id, _friendly_id, symbol] <- minted_tokens do
      friendly_id = MintedToken.build_friendly_id(symbol, id)

      query =
        from(k in "key",
             where: k.id == ^id,
             update: [set: [friendly_id: ^friendly_id]])

      Repo.update_all(query, [])
    end
  end
end
