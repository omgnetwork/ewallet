defmodule EWalletDB.Repo.Migrations.AddLedgerToTokenTable do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  def up do
    alter table(:token) do
      add :ledger, :string
    end

    create index(:token, [:ledger])

    flush()
    _ = set_default_ledger_value(:token, "local")

    # Now that every token should have a value in the ledger column now, disable null.
    alter table(:token) do
      modify :ledger, :string, null: false
    end
  end

  defp set_default_ledger_value(table, value) do
    table = Atom.to_string(table)

    query = from(t in table,
                 where: is_nil(t.ledger),
                 update: [set: [ledger: ^value]])

    Repo.update_all(query, [])
  end

  def down do
    alter table(:token) do
      remove :ledger
    end
  end
end
