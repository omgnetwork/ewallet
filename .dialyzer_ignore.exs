[
  # Warnings from `Arc.Ecto.Schema.cast_attachments/3` macro that we couldn't touch
  {"apps/ewallet_db/lib/ewallet_db/account.ex", :pattern_match},
  {"apps/ewallet_db/lib/ewallet_db/user.ex", :pattern_match},

  # `Account.load_accounts/1` uses `query_result.columns` which is available in `%Postgrex.Result{}`
  # but not for other adapters. Hence not returned in typespec of `Ecto.Adapters.SQL.query/4`.
  {"apps/ewallet_db/lib/ewallet_db/account.ex", :no_return},

  # TODO: Remove extra attributes e.g. `Map.put(wallet, :account_id, account.id)` from `%Wallet{}`
  {"apps/ewallet/lib/ewallet/gates/transaction_consumption_consumer_gate.ex", :call}
]
