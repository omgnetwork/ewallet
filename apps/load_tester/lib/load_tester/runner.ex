defmodule LoadTester.Runner do
  use Chaperon.LoadTest
  alias LoadTester.Scenarios.{
    AccountAll,
    AccountGetWallets,
    AdminLogin,
    TokenAll,
    TransactionCreate,
    UserGetWallets
  }

  @iterations 10
  @steps [
    AdminLogin,
    UserGetWallets,
    TokenAll,
    AccountAll,
    AccountGetWallets,
    TransactionCreate
  ]

  def default_config, do: %{
    base_url: "https://ewallet.staging.omisego.io"
    # base_url: "http://localhost:4000"
  }

  def scenarios, do: [
    {{@iterations, @steps}, %{}}
  ]
end
