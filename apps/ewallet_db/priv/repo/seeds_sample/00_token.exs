defmodule EWalletDB.Repo.Seeds.TokenSampleSeed do
  alias Ecto.UUID
  alias EWallet.MintGate
  alias EWallet.Web.Preloader
  alias EWalletDB.{Account, Token}
  alias EWalletDB.Seeder

  @seed_data [
    %{
      symbol: "OMG",
      name: "OmiseGO",
      subunit_to_unit: 1_000_000_000_000_000_000,
      genesis_amount: 1_000_000_000_000_000_000_000_000, # 1,000,000 OMG
      account_name: "master_account",
      originator: %Seeder{}
    },
    %{
      symbol: "KNC",
      name: "Kyber",
      subunit_to_unit: 1_000_000_000_000_000_000,
      genesis_amount: 1_000_000_000_000_000_000_000_000,  # 1,000,000 KNC
      account_name: "master_account",
      originator: %Seeder{}
    },
    %{
      symbol: "BTC",
      name: "Bitcoin",
      subunit_to_unit: 1_000_000_000_000_000_000,
      genesis_amount: 1_000_000_000_000_000_000_000_000, # 1,000,000 BTC
      account_name: "master_account",
      originator: %Seeder{}
    },
    %{
      symbol: "OEM",
      name: "One EM",
      subunit_to_unit: 1_000_000_000_000_000_000,
      genesis_amount: 1_000_000_000_000_000_000_000_000, # 1,000,000 OEM
      account_name: "master_account",
      originator: %Seeder{}
    },
    %{
      symbol: "ETH",
      name: "Ether",
      subunit_to_unit: 1_000_000_000_000_000_000,
      genesis_amount: 1_000_000_000_000_000_000_000_000, # 1,000,000 ETH
      account_name: "master_account",
      originator: %Seeder{}
    },
  ]

  def seed do
    [
      run_banner: "Seeding sample tokens:",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    Enum.each @seed_data, fn data ->
      run_with(writer, data)
    end
  end

  defp run_with(writer, data) do
    case Token.get_by(symbol: data.symbol) do
      nil ->
        account = Account.get_by(name: data.account_name)
        data = Map.put(data, :account_uuid, account.uuid)

        case Token.insert(data) do
          {:ok, token} ->
            {:ok, token} = Preloader.preload_one(token, :account)
            writer.success("""
              ID              : #{token.id}
              Subunit to unit : #{token.subunit_to_unit}
              Account Name    : #{token.account.name}
              Account ID      : #{token.account.id}
            """)
            mint_with(writer, data, token)
          {:error, changeset} ->
            writer.error("  Token #{data.symbol} could not be inserted.")
            writer.print_errors(changeset)
          _ ->
            writer.error("  Token #{data.symbol} could not be inserted.")
            writer.error("  Unknown error.")
        end
      %Token{} = token ->
        {:ok, token} = Preloader.preload_one(token, :account)
        writer.warn("""
          ID              : #{token.id}
          Subunit to unit : #{token.subunit_to_unit}
          Account Name    : #{token.account.name}
          Account ID      : #{token.account.id}
        """)
    end
  end

  defp mint_with(writer, data, token) do
    mint_data = %{
      "idempotency_token" => UUID.generate(),
      "token_id" => token.id,
      "amount" => data.genesis_amount,
      "description" => "Seeded #{data.genesis_amount} #{token.id}.",
      "metadata" => %{},
      "originator" => %Seeder{}
    }

    case MintGate.insert(mint_data) do
      {:ok, mint, transaction} ->
        writer.success("""
            Token ID  : #{token.id}
            Amount (subunit) : #{mint.amount}
            Confirmed?       : #{mint.confirmed}
            From address     : #{transaction.from || '<not set>'}
            To address       : #{transaction.to || '<not set>'}
        """)
      {:error, changeset} ->
        writer.error("    #{token.symbol} could not be minted:")
        writer.print_errors(changeset)
      _ ->
        writer.error("    #{token.symbol} could not be minted:")
        writer.error("    Unknown error.")
    end
  end
end
