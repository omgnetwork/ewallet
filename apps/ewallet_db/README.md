# eWalletDB

eWalletDB (a.k.a the `EWalletDB` module in the code) is the eWallet's sub-app
that allows connectivity to the eWallet's database by other sub-apps.

This is a part of the eWallet umbrella app. You can start this sub-application
by starting the global umbrella application rather that this one specifically.

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

# Get by another field
Struct.get_by(atom, value :: any(), opts \\ [])
User.get_by(:email, "email@example.com")
User.get_by(:email, "email@example.com", preload: :accounts)

# Get by multiple fields
Struct.get_by(map, opts \\ [])
User.get_by(%{email: "email@example.omc", status: "active"})
User.get_by(%{email: "email@example.omc", status: "active"}, preload: :accounts)
```

#### Get multiple records

```ex
# Get by id
Struct.all(uuid, opts \\ [])
User.all("9858570e-0a1f-4e4a-a630-4752aa04021c")
User.all("9858570e-0a1f-4e4a-a630-4752aa04021c", preload: :accounts)

# Get by another field
Struct.all_by(atom, value :: any(), opts \\ [])
User.all_by(:email, "email@example.com")
User.all_by(:email, "email@example.com", preload: :accounts)

# Get by multiple fields
Struct.all_by(map, opts \\ [])
User.all_by(%{email: "email@example.omc", status: "active"})
User.all_by(%{email: "email@example.omc", status: "active"}, preload: :accounts)
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
