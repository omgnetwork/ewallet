defmodule EWalletDB.Repo.Migrations.AddUlidToSchemas do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo
  alias ExULID.ULID

  @tables [
    # table_atom: "prefix",
    api_key: "aky_",
    auth_token: "atk_",
    balance: "bal_",
    key: "key_",
    mint: "mnt_",
    minted_token: "tok_",
    transaction_request: "txr",
    transaction_consumption: "txc",
    transfer: "tfr",
    user: "usr_"
  ]

  def up do
    Enum.each(@tables, fn({table_name, prefix}) ->
      alter table(table_name) do
        add :id, :string
      end

      create index(table_name, [:id])

      flush()

      table_name
      |> Atom.to_string()
      |> populate_id(prefix)
    end)
  end

  def down do
    Enum.each(@tables, fn({table_name, _prefix}) ->
      alter table(table_name) do
        remove :id
      end
    end)
  end

  defp populate_id(table_name, prefix) do
    query = from(t in table_name,
                 select: [t.uuid, t.inserted_at],
                 lock: "FOR UPDATE")

    for [uuid, inserted_at] <- Repo.all(query) do
      with {date, {hours, minutes, seconds, microseconds}} <- inserted_at,
           erlang_time <- {date, {hours, minutes, seconds}},
           {:ok, naive} <- NaiveDateTime.from_erl(erlang_time, {microseconds, 6}),
           {:ok, datetime} <- DateTime.from_naive(naive, "Etc/UTC"),
           unix_time <- DateTime.to_unix(datetime, :millisecond),
           ulid <- prefix <> ULID.generate(unix_time)
      do
        query = from(t in table_name,
                     where: t.uuid == ^uuid,
                     update: [set: [id: ^ulid]])

        Repo.update_all(query, [])
      end
    end
  end
end
