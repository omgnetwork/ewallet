defmodule EWalletDB.Repo.Migrations.RenameIdToUuid do
  use Ecto.Migration

  @tables [
    :account,
    :api_key,
    :auth_token,
    :balance,
    :forget_password_request,
    :invite,
    :key,
    :membership,
    :mint,
    :minted_token,
    :role,
    :transaction_consumption,
    :transaction_request,
    :transfer,
    :user
  ]

  def up do
    Enum.each(@tables, fn(table) ->
      rename table(table), :id, to: :uuid
    end)
  end

  def down do
    Enum.each(@tables, fn(table) ->
      rename table(table), :uuid, to: :id
    end)
  end
end
