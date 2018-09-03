defmodule LocalLedgerDB.Repo.Migrations.UpdateGenesisAddressInWallet do
  use Ecto.Migration
  import Ecto.Query
  alias Ecto.{DateTime, UUID}
  alias LocalLedgerDB.Repo

  @old_address "genesis"
  @new_address "gnis000000000000"

  def up do
    case get_wallet_metadatas(@old_address) do
      {encrypted_metadata, metadata} ->
        insert("wallet", @new_address, encrypted_metadata, metadata)

        update("entry", :wallet_address, @old_address, @new_address)
        update("cached_balance", :wallet_address, @old_address, @new_address)

        delete("wallet", :address, @old_address)

      _ ->
        :noop
    end
  end

  def down do
    case get_wallet_metadatas(@new_address) do
      {encrypted_metadata, metadata} ->
        insert("wallet", @old_address, encrypted_metadata, metadata)

        update("entry", :wallet_address, @new_address, @old_address)
        update("cached_balance", :wallet_address, @new_address, @old_address)

        delete("wallet", :address, @new_address)

      _ ->
        :noop
    end
  end

  defp get_wallet_metadatas(address) do
    query =
      from(w in "wallet",
        select: {w.encrypted_metadata, w.metadata},
        where: w.address == ^address,
        limit: 1
      )

    Repo.one(query)
  end

  defp insert("wallet", address, encrypted_metadata, metadata) do
    attrs = %{
      uuid: UUID.bingenerate(),
      address: address,
      inserted_at: DateTime.autogenerate(),
      updated_at: DateTime.autogenerate(),
      encrypted_metadata: encrypted_metadata,
      metadata: metadata
    }

    insert("wallet", attrs)
  end

  defp insert(table, attrs) do
    {1, nil} = Repo.insert_all(table, [attrs])
  end

  defp update(table, field_name, from_value, to_value) do
    update_args = Keyword.new([{field_name, to_value}])

    query =
      from(t in table,
        where: field(t, ^field_name) == ^from_value,
        update: [set: ^update_args]
      )

    {_, nil} = Repo.update_all(query, [])
  end

  defp delete(table, field_name, value) do
    delete_query = from(w in table, where: field(w, ^field_name) == ^value)
    {1, nil} = Repo.delete_all(delete_query)
  end
end
