defmodule EWalletDB.Repo.Seeds.MintedTokenSampleSeed do
  alias Ecto.UUID
  alias EWallet.MintGate
  alias EWallet.Web.Preloader
  alias EWalletDB.{Account, MintedToken}

  @seed_data [
    %{
      symbol: "OMG",
      name: "OmiseGO",
      subunit_to_unit: 10_000,
      genesis_amount: 10_000_000_000, # 1,000,000 OMG
      account_name: "master_account"
    },
    %{
      symbol: "KNC",
      name: "Kyber",
      subunit_to_unit: 1_000,
      genesis_amount: 1_000_000_000,  # 1,000,000 KNC
      account_name: "master_account"
    },
    %{
      symbol: "BTC",
      name: "Bitcoin",
      subunit_to_unit: 10_000,
      genesis_amount: 10_000_000_000, # 1,000,000 BTC
      account_name: "master_account"
    },
    %{
      symbol: "OEM",
      name: "One EM",
      subunit_to_unit: 100,
      genesis_amount: 100_000_000, # 1,000,000 OEM
      account_name: "master_account"
    },
    %{
      symbol: "ETH",
      name: "Ether",
      subunit_to_unit: 1_000_000_000_000_000_000,
      genesis_amount: 1_000_000_000_000_000_000_000_000, # 1,000,000 ETH
      account_name: "master_account"
    },
  ]

  def seed do
    [
      run_banner: "Seeding sample minted tokens:",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    Enum.each @seed_data, fn data ->
      run_with(writer, data)
    end
  end

  defp run_with(writer, data) do
    case MintedToken.get_by(symbol: data.symbol) do
      nil ->
        account = Account.get_by(name: data.account_name)
        data = Map.put(data, :account_uuid, account.uuid)

        case MintedToken.insert(data) do
          {:ok, minted_token} ->
            minted_token = Preloader.preload(minted_token, :account)
            writer.success("""
              ID              : #{minted_token.id}
              Subunit to unit : #{minted_token.subunit_to_unit}
              Account Name    : #{minted_token.account.name}
              Account ID      : #{minted_token.account.id}
            """)
            mint_with(writer, data, minted_token)
          {:error, changeset} ->
            writer.error("  MintedToken #{data.symbol} could not be inserted.")
            writer.print_errors(changeset)
          _ ->
            writer.error("  MintedToken #{data.symbol} could not be inserted.")
            writer.error("  Unknown error.")
        end
      %MintedToken{} = minted_token ->
        minted_token = Preloader.preload(minted_token, :account)
        writer.warn("""
          ID              : #{minted_token.id}
          Subunit to unit : #{minted_token.subunit_to_unit}
          Account Name    : #{minted_token.account.name}
          Account ID      : #{minted_token.account.id}
        """)
    end
  end

  defp mint_with(writer, data, minted_token) do
    mint_data = %{
      "idempotency_token" => UUID.generate(),
      "token_id" => minted_token.id,
      "amount" => data.genesis_amount,
      "description" => "Seeded #{data.genesis_amount} #{minted_token.id}.",
      "metadata" => %{}
    }

    case MintGate.insert(mint_data) do
      {:ok, mint, transfer} ->
        writer.success("""
            Minted Token ID  : #{minted_token.id}
            Amount (subunit) : #{mint.amount}
            Confirmed?       : #{mint.confirmed}
            From address     : #{transfer.from || '<not set>'}
            To address       : #{transfer.to || '<not set>'}
        """)
      {:error, changeset} ->
        writer.error("    #{minted_token.symbol} could not be minted:")
        writer.print_errors(changeset)
      _ ->
        writer.error("    #{minted_token.symbol} could not be minted:")
        writer.error("    Unknown error.")
    end
  end
end
