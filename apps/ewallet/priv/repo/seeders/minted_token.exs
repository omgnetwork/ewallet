# This is the seeding script for MintedToken.
alias Ecto.UUID
alias EWallet.{CLI, MintGate, Seeder}
alias EWalletDB.{Account, MintedToken, Repo}

seeds = [
  %{
    symbol: "OMG",
    name: "OmiseGO",
    subunit_to_unit:        10_000,
    genesis_amount: 10_000_000_000, # 1,000,000 OMG
    account_id: Account.get_master_account().id
  },
  %{
    symbol: "KNC",
    name: "Kyber",
    subunit_to_unit:        1_000,
    genesis_amount: 1_000_000_000,  # 1,000,000 KNC
    account_id: Account.get_master_account().id
  },
  %{
    symbol: "BTC",
    name: "Bitcoin",
    subunit_to_unit:        10_000,
    genesis_amount: 10_000_000_000, # 1,000,000 BTC
    account_id: Account.get_master_account().id
  },
  %{
    symbol: "OEM",
    name: "One EM",
    subunit_to_unit:        100,
    genesis_amount: 100_000_000, # 1,000,000 OEM
    account_id: Account.get_master_account().id
  },
  %{
    symbol: "ETH",
    name: "Ether",
    subunit_to_unit:        1_000_000_000_000_000_000,
    genesis_amount: 1_000_000_000_000_000_000_000_000, # 1,000,000 ETH
    account_id: Account.get_master_account().id
  },
]

Enum.each(seeds, fn(data) ->
  with nil                 <- Repo.get_by(MintedToken, symbol: data.symbol),
       {:ok, _minted_token} <- MintedToken.insert(data)
  do
    nil
  else
    %MintedToken{} ->
      nil
    {:error, changeset} ->
      CLI.error("MintedToken #{data.symbol} could not be inserted:")
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("MintedToken #{data.symbol} could not be inserted:")
      CLI.error("  Unable to parse the provided error.\n")
  end
end)

Enum.each(seeds, fn(data) ->
  minted_token = Repo.get_by(MintedToken, symbol: data.symbol)

  mint_data = %{
    "idempotency_token" => UUID.generate(),
    "token_id" => minted_token.friendly_id,
    "amount" => data.genesis_amount,
    "description" => "Seeded #{data.genesis_amount} #{minted_token.friendly_id}.",
    "metadata" => %{}
  }

  case MintGate.insert(mint_data) do
    {:ok, _mint, _transfer} ->
      nil
    {:error, changeset} ->
      CLI.error("#{minted_token.symbol} could not be minted:")
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("#{minted_token.symbol} could not be minted:")
      CLI.error("  Unable to parse the provided error.\n")
  end
end)
