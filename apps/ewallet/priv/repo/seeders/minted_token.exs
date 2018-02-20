# This is the seeding script for MintedToken.

seeds = [
  %{
    symbol: "OMG",
    name: "OmiseGO",
    subunit_to_unit:        10_000,
    genesis_amount: 10_000_000_000, # 1,000,000 OMG
    account_id: EWalletDB.Account.get_by_name("master_account").id
  },
  %{
    symbol: "KNC",
    name: "Kyber",
    subunit_to_unit:        1_000,
    genesis_amount: 1_000_000_000,  # 1,000,000 KNC
    account_id: EWalletDB.Account.get_by_name("master_account").id
  },
  %{
    symbol: "BTC",
    name: "Bitcoin",
    subunit_to_unit:        10_000,
    genesis_amount: 10_000_000_000, # 1,000,000 BTC
    account_id: EWalletDB.Account.get_by_name("master_account").id
  },
  %{
    symbol: "OEM",
    name: "One EM",
    subunit_to_unit:        100,
    genesis_amount: 100_000_000, # 1,000,000 OEM
    account_id: EWalletDB.Account.get_by_name("master_account").id
  },
  %{
    symbol: "ETH",
    name: "Ether",
    subunit_to_unit:        1_000_000_000_000_000_000,
    genesis_amount: 1_000_000_000_000_000_000_000_000, # 1,000,000 ETH
    account_id: EWalletDB.Account.get_by_name("master_account").id
  },
]

EWallet.CLI.info("\nSeeding MintedToken...")

Enum.each(seeds, fn(data) ->
  with nil <- EWalletDB.Repo.get_by(EWalletDB.MintedToken, symbol: data.symbol),
       {:ok, _} <- EWalletDB.MintedToken.insert(data)
  do
    EWallet.CLI.success("MintedToken inserted: #{data.symbol}")
  else
    %EWalletDB.MintedToken{} ->
      EWallet.CLI.warn("MintedToken #{data.symbol} is already in DB")
    {:error, _} ->
      EWallet.CLI.error("MintedToken #{data.symbol}"
        <> " could not be inserted due to an error")
  end
end)

Enum.each(seeds, fn(data) ->
  minted_token = EWalletDB.Repo.get_by(EWalletDB.MintedToken, symbol: data.symbol)

  {:ok, _mint, _transfer} = EWallet.Mint.insert(%{
    "idempotency_token" => Ecto.UUID.generate(),
    "token_id" => minted_token.friendly_id,
    "amount" => data.genesis_amount,
    "description" => "Seeded #{data.genesis_amount} #{minted_token.friendly_id}.",
    "metadata" => %{}
  })
end)
