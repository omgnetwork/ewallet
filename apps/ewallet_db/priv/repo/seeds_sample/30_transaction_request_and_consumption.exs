defmodule EWalletDB.Repo.Seeds.TransactionRequestSeed do
  alias Ecto.UUID
  alias EWallet.TransactionConsumptionConfirmerGate
  alias EWallet.Web.Preloader
  alias EWalletDB.{Account, Token, TransactionRequest, TransactionConsumption, User}

  @num_requests 20
  @request_correlation_id_prefix "transaction_request_"
  @request_values %{
    types: ["send", "receive"],
    token_symbols: ["OMG", "ETH", "OEM", "BTC"],
    allow_amount_overrides: [false],
    require_confirmations: [true, false],
    consumption_lifetimes: [nil, 10000, 2000000],
    max_consumptions: [nil, 1, 10, 100],
    max_consumptions_per_user: [nil, 1, 10],
    consumed: [true, false]
  }

  @consumption_values %{
    provider_user_ids: ["provider_user_id01", "provider_user_id02", "provider_user_id03"]
  }

  def seed do
    [
      run_banner: "Seeding sample transaction requests:",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    Enum.each 1..@num_requests, fn num ->
      run_with(writer, num)
    end
  end

  def run_with(writer, num) do
    correlation_id = @request_correlation_id_prefix <> to_string(num)

    case TransactionRequest.get_by(correlation_id: correlation_id) do
      nil ->
        {:ok, request} = request(correlation_id, @request_values, writer)

        if Enum.random(@request_values.consumed) == true do
          consume(request, @consumption_values, writer)
        end

      %TransactionRequest{} = request ->
        {:ok, request} = Preloader.preload_one(request, [:token, :wallet])

        writer.warn("""
          Transaction Request ID : #{request.id}
          Correlation ID         : #{request.correlation_id}
          Type                   : #{request.type}
          Amount (subunit)       : #{request.amount}
          Token                  : #{request.token.symbol}
          Wallet address         : #{request.wallet.address}
        """)
    end
  end

  defp request(correlation_id, request_values, writer) do
    correlation_id
    |> prepare_request(request_values)
    |> TransactionRequest.insert()
    |> case do
      {:ok, request} ->
        {:ok, request} = Preloader.preload_one(request, [:token, :wallet])

        writer.success("""
          Transaction Request ID : #{request.id}
          Correlation ID         : #{request.correlation_id}
          Type                   : #{request.type}
          Amount (subunit)       : #{request.amount}
          Token                  : #{request.token.symbol}
          Wallet address         : #{request.wallet.address}
        """)

        {:ok, request}

      {:error, changeset} ->
        writer.error("  Transaction request could not be inserted:")
        writer.print_errors(changeset)

      _ ->
        writer.error("  Transaction request could not be inserted:")
        writer.error("  Unknown error.")
    end
  end

  defp consume(request, consumption_values, writer) do
    request
    |> prepare_consumption(consumption_values)
    |> TransactionConsumption.insert()
    |> case do
      {:ok, consumption} ->
        consumption = TransactionConsumption.approve(consumption)
        {:ok, consumption} = Preloader.preload_one(consumption, [:token, :wallet, :transaction_request])
        {:ok, consumption} = TransactionConsumptionConfirmerGate.approve_and_confirm(request, consumption)

        writer.success("""
            Transaction Consumption ID : #{consumption.id}
            Amount (subunit)           : #{consumption.amount}
            Token                      : #{consumption.token.symbol}
            Wallet address             : #{consumption.wallet.address}
        """)

        {:ok, consumption}

      {:error, changeset} ->
        writer.error("  Transaction consumption could not be inserted:")
        writer.print_errors(changeset)

      _ ->
        writer.error("  Transaction consumption could not be inserted:")
        writer.error("  Unknown error.")
    end
  end

  defp prepare_request(correlation_id, attrs) do
    account = Account.get_master_account()
    token_symbol = rand(attrs.token_symbols)

    %{
      type: rand(attrs.types),
      amount: :rand.uniform(100) * 1_000_000_000_000_000_000 |> round(),
      account_uuid: account.uuid,
      correlation_id: correlation_id,
      token_uuid: Token.get_by(symbol: token_symbol).uuid,
      wallet_address: Account.get_primary_wallet(account).address,
      allow_amount_override: rand(attrs.allow_amount_overrides),
      require_confirmation: rand(attrs.require_confirmations),
      consumption_lifetime: rand(attrs.consumption_lifetimes),
      metadata: %{},
      encrypted_metadata: %{},
      expiration_date: nil,
      max_consumptions: rand(attrs.max_consumptions),
      max_consumptions_per_user: rand(attrs.max_consumptions_per_user),
      exchange_account_id: nil,
      exchange_wallet_address: nil,
    }
  end

  defp prepare_consumption(request, attrs) do
    user = User.get_by(provider_user_id: Enum.random(attrs.provider_user_ids))
    user_wallet = User.get_primary_wallet(user)

    %{
      idempotency_token: UUID.generate(),
      amount: request.amount,
      user_uuid: user.uuid,
      token_uuid: request.token.uuid,
      transaction_request_uuid: request.uuid,
      wallet_address: user_wallet.address,
      estimated_request_amount: request.amount,
      estimated_consumption_amount: request.amount,
    }
  end

  defp rand(list), do: Enum.random(list)
end
