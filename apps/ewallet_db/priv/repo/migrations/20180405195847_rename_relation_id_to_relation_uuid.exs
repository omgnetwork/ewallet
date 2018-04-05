defmodule EWalletDB.Repo.Migrations.RenameRelationIdToRelationUuid do
  use Ecto.Migration

  @tables [
    account: [
      parent_id: :parent_uuid
    ],
    api_key: [
      account_id: :account_uuid
    ],
    auth_token: [
      user_id: :user_uuid
    ],
    balance: [
      user_id: :user_uuid,
      minted_token_id: :minted_token_uuid,
      account_id: :account_uuid
    ],
    forget_password_request: [
      user_id: :user_uuid
    ],
    invite: [],
    key: [
      account_id: :account_uuid
    ],
    membership: [
      user_id: :user_uuid,
      account_id: :account_uuid,
      role_id: :role_uuid
    ],
    mint: [
      minted_token_id: :minted_token_uuid,
      account_id: :account_uuid,
      transfer_id: :transfer_uuid
    ],
    minted_token: [
      account_id: :account_uuid
    ],
    role: [],
    transaction_consumption: [
      transfer_id: :transfer_uuid,
      user_id: :user_uuid,
      account_id: :account_uuid,
      transaction_request_id: :transaction_request_uuid,
      minted_token_id: :minted_token_uuid
    ],
    transaction_request: [
      user_id: :user_uuid,
      account_id: :account_uuid,
      minted_token_id: :minted_token_uuid
    ],
    transfer: [
      minted_token_id: :minted_token_uuid
    ],
    user: [
      invite_id: :invite_uuid
    ]
  ]

  def up do
    Enum.each(@tables, fn({table, maps}) ->
      Enum.each(maps, fn({old, new}) ->
        rename table(table), old, to: new
      end)
    end)
  end

  def down do
    Enum.each(@tables, fn({table, maps}) ->
      Enum.each(maps, fn({old, new}) ->
        rename table(table), new, to: old
      end)
    end)
  end
end
