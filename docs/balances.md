# Balances

This file contains information about the balance system and how it can be used.

## Understanding the balance system

Balances are used to "hold" amounts in specific minted tokens (a.k.a cryptocurrencies/loyalty/points/coins). Hold is between quotes because those amounts are not actually stored in any records, they are computed from the local ledger (using a Double Bookkeeping approach) by summing all the credits and subtracting all the debits.

Balances are saved in Kubera DB, and a shadow copy is made in Caishen to ensure data consistency at the database level. Those balances have three fields that really matter: address, name and identifier.

- `address`: The balance ID used to transfer funds to that balance.
- `name`: A modifiable field used to identify a specific balance. By default, the identifier will be used as a name.
- `identifier`: An identifier acting both as a type and a unique identifier in the scope of the current account or user.
  - Can contain: `genesis`, `burn`, `primary`, `secondary:#{uuid}`
  - The `genesis` balance will be lazy-created the first time it's needed. A primary balance is created for users and accounts on creation (accounts also get a burn balance).
  - The value has to be unique in the scope of the current account/user: One account can only have one primary and one burn balances. Multiple secondary balances can be created by adding a generated `uuid`. The `genesis` balance has no user or account associated and is the only one working that way.
  - Secondary balances are not available yet, but it should be possible in the future for users to create alternative balances (like different bank accounts for example), and potentially change their primary address.

## The minting process

When minting, tokens are taken from the genesis (the only balance allowed to go in the negative in the DEB ledger) and transferred into the primary balance of the master account (there can only be one master account per eWallet). It is then possible for an admin to transfer funds from that primary balance (associated with the master account) to any other account's balance.

## The burn balance

The burn balance is an optional balance that can be used to get rid of tokens. It makes sense in the case of loyalty points for example, where a provider would want points to disappear once they've been redeemed. That's what the burn balance is for: by specifying a `burn_balance_identifier` (default is `burn`) when doing debits and credits, the specified burn balance will be used instead of the primary address.

## Crediting or debiting from a specific account

When debiting or crediting, it is also possible to specify which account (with the `account_id` parameter) is being used. The primary balance of that given account will be used to get funds in case of a credit, or where will the funds be returned in case of a debit. By default, if no account is specified, the master account will be used.
