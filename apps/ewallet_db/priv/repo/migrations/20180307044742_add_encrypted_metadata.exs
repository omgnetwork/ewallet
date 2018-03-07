defmodule EWalletDB.Repo.Migrations.AddEncryptedMetadata do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  @tables [:balance, :minted_token, :transfer, :user]

  def up do
    Enum.each(@tables, fn table_name ->
      alter table(table_name) do
        add :encrypted_metadata, :binary
      end

      flush()
      table_name |> Atom.to_string() |> migrate_to_encrypted_metadata()

      alter table(table_name) do
        remove :metadata
        add :metadata, :map, null: false, default: "{}"
      end
    end)
  end

  def down do
    Enum.each(@tables, fn table_name ->
      alter table(table_name) do
        remove :metadata
        add :metadata, :binary
      end

      flush()
      table_name |> Atom.to_string() |> migrate_to_metadata()

      alter table(table_name) do
        remove :encrypted_metadata
      end
    end)
  end

  defp migrate_to_encrypted_metadata(table_name) do
    query = from(b in table_name,
                 select: [b.id, b.metadata],
                 lock: "FOR UPDATE")

    for [id, metadata] <- Repo.all(query) do
      query = from(b in table_name,
                  where: b.id == ^id,
                  update: [set: [encrypted_metadata: ^metadata]])
      Repo.update_all(query, [])
    end
  end

  defp migrate_to_metadata(table_name) do
    query = from(b in table_name,
                 select: [b.id, b.encrypted_metadata],
                 lock: "FOR UPDATE")

    for [id, encrypted_metadata] <- Repo.all(query) do
      query = from(b in table_name,
                  where: b.id == ^id,
                  update: [set: [metadata: ^encrypted_metadata]])
      Repo.update_all(query, [])
    end
  end
end
