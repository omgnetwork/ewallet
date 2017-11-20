# This is the seeding script for MintedToken.

seeds = [
  %{
    symbol: "OMG",
    name: "OmiseGO",
    subunit_to_unit:        10_000,
    genesis_amount: 10_000_000_000, # 1,000,000 OMG
    account: KuberaDB.Account.get("account1")
  },
  %{
    symbol: "KNC",
    name: "Kyber",
    subunit_to_unit:        1_000,
    genesis_amount: 1_000_000_000,  # 1,000,000 KNC
    account: KuberaDB.Account.get("account1")
  },
  %{
    symbol: "BTC",
    name: "Bitcoin",
    subunit_to_unit:        10_000,
    genesis_amount: 10_000_000_000, # 1,000,000 BTC
    account: KuberaDB.Account.get("account1")
  },
  %{
    symbol: "MNT",
    name: "Mint",
    subunit_to_unit:        100,
    genesis_amount: 100_000_000, # 1,000,000 MNT
    account: KuberaDB.Account.get("account2")
  },
  %{
    symbol: "ETH",
    name: "Ether",
    subunit_to_unit:        1_000_000_000_000_000_000,
    genesis_amount: 1_000_000_000_000_000_000_000_000, # 1,000,000 ETH
    account: KuberaDB.Account.get("account2")
  },
]

KuberaDB.CLI.info("\nSeeding MintedToken...")

Enum.each(seeds, fn(data) ->
  with nil <- KuberaDB.Repo.get_by(KuberaDB.MintedToken, symbol: data.symbol),
       {:ok, _} <- KuberaDB.MintedToken.insert(data)
  do
    KuberaDB.CLI.success("MintedToken inserted: #{data.symbol}")
  else
    %KuberaDB.MintedToken{} ->
      KuberaDB.CLI.warn("MintedToken #{data.symbol} is already in DB")
    {:error, _} ->
      KuberaDB.CLI.error("MintedToken #{data.symbol}"
        <> " could not be inserted due to an error")
  end
end)

if Enum.member?(System.argv, "--with-genesis") do
  Enum.each(seeds, fn(data) ->
    minted_token = KuberaDB.Repo.get_by(KuberaDB.MintedToken, symbol: data.symbol)
    {:ok, genesis} = KuberaDB.Balance.genesis()

    %{
      from: genesis,
      to: KuberaDB.MintedToken.get_master_balance(minted_token),
      minted_token: minted_token,
      amount: data.genesis_amount,
      metadata: %{}
    }
    |> KuberaMQ.Serializers.Transaction.serialize
    |> KuberaMQ.Entry.genesis
  end)
end
