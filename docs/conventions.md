# Conventions


## Naming conventions

In order for any developers to start working with eWalletDB quickly, easily and without ambiguity,
it is important to follow a naming convention when naming functions.
The conventions used throughout this `eWalletDB` project are described below:

### Functions

#### Get a single record

```ex
# Get by id
Struct.get(uuid, opts \\ [])
User.get("9858570e-0a1f-4e4a-a630-4752aa04021c")
User.get("9858570e-0a1f-4e4a-a630-4752aa04021c", preload: :accounts)

# Get by one or more fields
Struct.get_by(keyword_or_map, opts \\[])
User.get_by(username: "user01")
User.get_by([username: "user01", provider_user_id: "puid01"], preload: :accounts)
User.get_by(%{username: "user01", provider_user_id: "puid01"}, preload: :accounts)
```

#### Get multiple records

```ex
# Get all records
Struct.all(opts \\ [])
User.all()
User.all(preload: :accounts)

# Get records by one or more fields
Struct.all_by(keyword_or_map, opts \\ [])
User.all_by(username: "user01")
User.all_by([username: "user01", provider_user_id: "puid01"], preload: :accounts)
User.all_by(%{username: "user01", provider_user_id: "puid01"}, preload: :accounts)
```

#### Build a base query

A base query can be used for retrieving either one or multiple records.
This is useful for building a query that can be passed into a paginator
or to scope down more before fetching the results.

```ex
Struct.query()
User.query()
```

## Retrieving associations

Fetching records does not automatically load their associations.
In order to access the records' associations, one must preload them.

To make this more convenient and not having to use `EWalletDB.Repo.preload/3` everywhere,
the associations can be preloaded through the `get()`, `get_by()`, and `all()` functions
by passing the `:preload` option.

Consider a typical `get/2` call:

```ex
iex> EWalletDB.User.get("9858570e-0a1f-4e4a-a630-4752aa04021c")
%EWalletDB.User{
  # ...
  accounts: #Ecto.Association.NotLoaded<association :accounts is not loaded>,
  balances: #Ecto.Association.NotLoaded<association :users is not loaded>,
  # ...
}
```

Versus `get/2` with the `:preload` option:

```ex
iex> EWalletDB.User.get("9858570e-0a1f-4e4a-a630-4752aa04021c", preload: [:accounts, :balances])
%EWalletDB.User{
  # ...
  accounts: [%EWalletDB.Account{...}, %EWalletDB.Account{...}],
  balances: [%EWalletDB.Balance{...}, ...],
  # ...
}
```

It also allows deeply-nested preloading by providing nested keyword list into the `:preload` option:

```ex
iex> EWalletDB.User.get("9858570e-0a1f-4e4a-a630-4752aa04021c", preload: [accounts: :balances])
%EWalletDB.User{
  # ...
  accounts: [%EWalletDB.Account{
    # ...
    balances: [%EWalletDB.Balance{...}],
    # ...
  }]
  # ...
}
```
