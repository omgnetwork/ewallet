# This is the seeding script for MintedToken.

seeds = [
  %{
    symbol: "OMG",
    name: "OmiseGO",
    subunit_to_unit:        10_000,
    genesis_amount: 10_000_000_000, # 1,000,000 OMG
    account_id: EWalletDB.Account.get_by_name("account01").id
  },
  %{
    symbol: "KNC",
    name: "Kyber",
    subunit_to_unit:        1_000,
    genesis_amount: 1_000_000_000,  # 1,000,000 KNC
    account_id: EWalletDB.Account.get_by_name("account01").id
  },
  %{
    symbol: "BTC",
    name: "Bitcoin",
    subunit_to_unit:        10_000,
    genesis_amount: 10_000_000_000, # 1,000,000 BTC
    account_id: EWalletDB.Account.get_by_name("account01").id
  },
  %{
    symbol: "MNT",
    name: "Mint",
    subunit_to_unit:        100,
    genesis_amount: 100_000_000, # 1,000,000 MNT
    account_id: EWalletDB.Account.get_by_name("account01").id
  },
  %{
    symbol: "ETH",
    name: "Ether",
    subunit_to_unit:        1_000_000_000_000_000_000,
    genesis_amount: 1_000_000_000_000_000_000_000_000, # 1,000,000 ETH
    account_id: EWalletDB.Account.get_by_name("account01").id
  },
]

EWalletDB.CLI.info("\nSeeding MintedToken...")

Enum.each(seeds, fn(data) ->
  with nil <- EWalletDB.Repo.get_by(EWalletDB.MintedToken, symbol: data.symbol),
       {:ok, _} <- EWalletDB.MintedToken.insert(data)
  do
    EWalletDB.CLI.success("MintedToken inserted: #{data.symbol}")
  else
    %EWalletDB.MintedToken{} ->
      EWalletDB.CLI.warn("MintedToken #{data.symbol} is already in DB")
    {:error, _} ->
      EWalletDB.CLI.error("MintedToken #{data.symbol}"
        <> " could not be inserted due to an error")
  end
end)

if Enum.member?(System.argv, "--with-genesis") do
  Enum.each(seeds, fn(data) ->
    minted_token = EWalletDB.Repo.get_by(EWalletDB.MintedToken, symbol: data.symbol)
    account = EWalletDB.Account.get(minted_token.account_id)
    genesis = EWalletDB.Balance.get_genesis()

    %{
      from_balance: genesis,
      to_balance: EWalletDB.Account.get_primary_balance(account),
      minted_token: minted_token,
      amount: data.genesis_amount,
      metadata: %{}
    }
    |> EWalletMQ.Serializers.Transaction.serialize()
    |> EWalletMQ.Publishers.Entry.genesis(Ecto.UUID.generate())
  end)
end
