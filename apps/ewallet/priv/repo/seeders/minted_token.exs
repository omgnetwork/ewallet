# This is the seeding script for MintedToken.
alias Ecto.UUID
alias EWallet.{MintGate, Seeder}
alias EWallet.Seeder.CLI
alias EWallet.Web.Preloader
alias EWalletDB.{Account, MintedToken, Repo}

seeds = [
  %{
    symbol: "OMG",
    name: "OmiseGO",
    subunit_to_unit:        10_000,
    genesis_amount: 10_000_000_000, # 1,000,000 OMG
    account_uuid: Account.get_master_account().uuid
  },
  %{
    symbol: "KNC",
    name: "Kyber",
    subunit_to_unit:        1_000,
    genesis_amount: 1_000_000_000,  # 1,000,000 KNC
    account_uuid: Account.get_master_account().uuid
  },
  %{
    symbol: "BTC",
    name: "Bitcoin",
    subunit_to_unit:        10_000,
    genesis_amount: 10_000_000_000, # 1,000,000 BTC
    account_uuid: Account.get_master_account().uuid
  },
  %{
    symbol: "OEM",
    name: "One EM",
    subunit_to_unit:        100,
    genesis_amount: 100_000_000, # 1,000,000 OEM
    account_uuid: Account.get_master_account().uuid
  },
  %{
    symbol: "ETH",
    name: "Ether",
    subunit_to_unit:        1_000_000_000_000_000_000,
    genesis_amount: 1_000_000_000_000_000_000_000_000, # 1,000,000 ETH
    account_uuid: Account.get_master_account().uuid
  },
]

CLI.subheading("Seeding the minted tokens:\n")

Enum.each(seeds, fn(data) ->
  with nil                 <- Repo.get_by(MintedToken, symbol: data.symbol),
       {:ok, minted_token} <- MintedToken.insert(data),
       minted_token        <- Preloader.preload(minted_token, :account)
  do
    CLI.success("""
        ID              : #{minted_token.id}
        Subunit to unit : #{minted_token.subunit_to_unit}
        Account ID      : #{minted_token.account.id}
      """)
  else
    %MintedToken{} = minted_token ->
      minted_token = Preloader.preload(minted_token, :account)
      CLI.warn("""
          ID              : #{minted_token.id}
          Subunit to unit : #{minted_token.subunit_to_unit}
          Account ID      : #{minted_token.account.id}
        """)
    {:error, changeset} ->
      CLI.error("  MintedToken #{data.symbol} could not be inserted:")
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("  MintedToken #{data.symbol} could not be inserted:")
      CLI.error("  Unable to parse the provided error.\n")
  end
end)

CLI.subheading("Minting the seeded minted tokens:\n")

Enum.each(seeds, fn(data) ->
  minted_token = Repo.get_by(MintedToken, symbol: data.symbol)

  mint_data = %{
    "idempotency_token" => UUID.generate(),
    "token_id" => minted_token.id,
    "amount" => data.genesis_amount,
    "description" => "Seeded #{data.genesis_amount} #{minted_token.id}.",
    "metadata" => %{}
  }

  case MintGate.insert(mint_data) do
    {:ok, mint, transfer} ->
      CLI.success("""
          Minted Token ID  : #{minted_token.id}
          Amount (subunit) : #{mint.amount}
          Confirmed?       : #{mint.confirmed}
          From address     : #{transfer.from || '<nil>'}
          To address       : #{transfer.to || '<nil>'}
        """)
    {:error, changeset} ->
      CLI.error("  #{minted_token.symbol} could not be minted:")
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("  #{minted_token.symbol} could not be minted:")
      CLI.error("  Unable to parse the provided error.\n")
  end
end)
