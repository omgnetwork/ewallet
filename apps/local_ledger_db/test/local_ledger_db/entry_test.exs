defmodule LocalLedgerDB.EntryTest do
  use ExUnit.Case
  import LocalLedgerDB.Factory
  alias LocalLedgerDB.Entry
  alias LocalLedgerDB.Repo
  alias Ecto.Adapters.SQL
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "generates a UUID" do
    {res, entry} = :entry |> build |> Repo.insert

    assert res == :ok
    assert String.match?(entry.uuid,
                         ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/)
  end

  test "generates the inserted_at and updated_at values" do
    {res, entry} = :entry |> build |> Repo.insert

    assert res == :ok
    assert entry.inserted_at != nil
    assert entry.updated_at != nil
  end

  test "prevents the creation of an entry without transactions" do
    attrs = params_for(:entry, transactions: [])
    changeset = Entry.changeset(%Entry{}, attrs)

    refute changeset.valid?
  end

  test "allows creation of an entry with metadata" do
    {res, entry} = :entry |> build(%{metadata: %{e_id: "123"}}) |> Repo.insert

    assert res == :ok
    assert entry.metadata == %{e_id: "123"}
  end

  test "allows creation of an entry without metadata" do
    transactions = [params_for(:transaction)]
    attrs = params_for(:entry, transactions: transactions)
    changeset = Entry.changeset(%Entry{}, attrs)

    assert changeset.valid?
  end

  test "saves the encrypted metadata" do
    :entry |> build(%{metadata: %{e_id: "123"}}) |> Repo.insert

    {:ok, results} = SQL.query(Repo, "SELECT encrypted_metadata FROM entry", [])

    row = Enum.at(results.rows, 0)
    assert <<"SBX", 1, _::binary>> = Enum.at(row, 0)
  end
end
