defmodule EWalletDB.Repo.Migrations.UniquifyIdColumns do
  use Ecto.Migration

  @tables [
    :account,
    :api_key,
    :auth_token,
    :category,
    :key,
    :mint,
    # :token, # It already has a unique id index
    :transaction,
    :transaction_consumption,
    :transaction_request,
    :user,
    :wallet
  ]

  def up do
    :ok = Enum.each(@tables, &uniquify/1)
  end

  # :account requires customized code because it was called account_external_id_index
  defp uniquify(:account) do
    create unique_index(:account, [:id])
    drop index(:account, [:id], name: :account_external_id_index)
  end

  # :category requires customized code because it did not have an id index before
  defp uniquify(:category) do
    create unique_index(:category, [:id])
  end

  # :wallet requires customized code because it was called balance_id_index
  defp uniquify(:wallet) do
    create unique_index(:wallet, [:id])
    drop index(:wallet, [:id], name: :balance_id_index)
  end

  defp uniquify(table) do
    drop index(table, [:id], name: "#{Atom.to_string(table)}_id_index")
    create unique_index(table, [:id])
  end

  def down do
    :ok = Enum.each(@tables, &deuniquify/1)
  end

  # :account requires customized code because it was called account_external_id_index
  defp deuniquify(:account) do
    drop index(:account, [:id], name: :account_id_index)
    create index(:account, [:id], name: :account_external_id_index)
  end

  # :category requires customized code because it did not have an id index before
  defp deuniquify(:category) do
    drop index(:category, [:id])
  end

  # :wallet requires customized code because it was called balance_id_index
  defp deuniquify(:wallet) do
    drop index(:wallet, [:id], name: :wallet_id_index)
    create index(:wallet, [:id], name: :balance_id_index)
  end

  defp deuniquify(table) do
    drop index(table, [:id], name: "#{Atom.to_string(table)}_id_index")
    create index(table, [:id])
  end
end
