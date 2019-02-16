# Copyright 2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWalletDB.Repo.Migrations.UpdateConstraintNames do
  use Ecto.Migration

  @renames [
    # {table, from_constraint, to_constraint},
    {:account, "account_parent_id_fkey", "account_parent_uuid_fkey"},
    {:api_key, "api_key_account_id_fkey", "api_key_account_uuid_fkey"},
    {:auth_token, "auth_token_user_id_fkey", "auth_token_user_uuid_fkey"},
    {:forget_password_request, "forget_password_request_user_id_fkey", "forget_password_request_user_uuid_fkey"},
    {:key, "key_account_id_fkey", "key_account_uuid_fkey"},
    {:membership, "membership_account_id_fkey", "membership_account_uuid_fkey"},
    {:membership, "membership_user_id_fkey", "membership_user_uuid_fkey"},
    {:membership, "membership_role_id_fkey", "membership_role_uuid_fkey"},
    {:mint, "mint_account_id_fkey", "mint_account_uuid_fkey"},
    {:token, "minted_token_pkey", "token_pkey"},
    {:transaction, "transfer_pkey", "transaction_pkey"},
    {:transaction, "transfer_exchange_account_uuid_fkey", "transaction_exchange_account_uuid_fkey"},
    {:transaction_consumption, "transaction_request_consumption_pkey", "transaction_consumption_pkey"},
    {:transaction_consumption, "transaction_request_consumption_account_id_fkey", "transaction_consumption_account_uuid_fkey"},
    {:transaction_consumption, "transaction_request_consumption_user_id_fkey", "transaction_consumption_user_uuid_fkey"},
    {:transaction_consumption, "transaction_request_consumption_transaction_request_id_fkey", "transaction_consumption_transaction_request_uuid_fkey"},
    {:transaction_request, "transaction_request_user_id_fkey", "transaction_request_user_uuid_fkey"},
    {:transaction_request, "transaction_request_account_id_fkey", "transaction_request_account_uuid_fkey"},
    {:user, "user_invite_id_fkey", "user_invite_uuid_fkey"},
    {:wallet, "balance_pkey", "wallet_pkey"},
    {:wallet, "balance_account_id_fkey", "wallet_account_uuid_fkey"},
    {:wallet, "balance_user_id_fkey", "wallet_user_uuid_fkey"}
  ]

  def up do
    Enum.each(@renames, fn {table, from, to} ->
      rename_constraint(table, from, to)
    end)
  end

  def down do
    Enum.each(@renames, fn {table, from, to} ->
      rename_constraint(table, to, from)
    end)
  end

  defp rename_constraint(table, from_constraint, to_constraint) do
    execute ~s/ALTER TABLE "#{table}" RENAME CONSTRAINT "#{from_constraint}" TO "#{to_constraint}"/
  end
end
