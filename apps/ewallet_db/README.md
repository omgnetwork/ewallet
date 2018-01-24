# eWalletDB

eWalletDB (written in code as `EWalletDB` module) is the eWallet's sub-app that allows connectivity to eWallet's database by other sub-apps.

This is a part of eWallet's umbrella app. Please start this app by starting the umbrella app rather than this specific app.

## Naming conventions

In order for any developers to start interfacing with eWalletDB quickly, easily and without ambiguity, it is important to follow a naming convention when naming functions. The recommendation is as follows:

### Functions

#### Get a single record

```ex
# Get by id
Struct.get(uuid, opts \\ [])
User.get("9858570e-0a1f-4e4a-a630-4752aa04021c")
User.get("9858570e-0a1f-4e4a-a630-4752aa04021c", preload: :accounts)

# Get by another field
Struct.get(atom, value :: any(), opts \\ [])
User.get(:email, "email@example.com")
User.get(:email, "email@example.com", preload: :accounts)

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
Struct.all(atom, value :: any(), opts \\ [])
User.all(:email, "email@example.com")
User.all(:email, "email@example.com", preload: :accounts)

# Get by multiple fields
Struct.all_by(map, opts \\ [])
User.all_by(%{email: "email@example.omc", status: "active"})
User.all_by(%{email: "email@example.omc", status: "active"}, preload: :accounts)
```

#### Build a base query

A base query can be both for getting either one or multiple records.
This is useful for building a query for sending into paginator or to scope down more before fetching the results.

```ex
Struct.query()
User.query()
```

## Retrieving associations

Fetching a record(s) does not automatically load its association. In order to access the record's association, one must preload it first.

To make this more convenient and not coupling `EWalletDB.Repo.preload/3` everywhere, the association(s) can be preloaded along with `get()`, `get_by()`, and `all()` functions by passing the option `:preload`.

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

Versus `get/2` with `:preload` option:

```ex
iex> EWalletDB.User.get("9858570e-0a1f-4e4a-a630-4752aa04021c", preload: [:accounts, :balances])
%EWalletDB.User{
  # ...
  accounts: [%EWalletDB.Account{...}, %EWalletDB.Account{...}],
  balances: [%EWalletDB.Balance{...}, ...],
  # ...
}
```

It also allows deeply-nested preloading by providing nested keyword list into `:preload` option:

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
