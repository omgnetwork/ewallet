defmodule LoadTester.Runner do
  use Chaperon.LoadTest
  alias LoadTester.Scenarios.{
    AccountAll,
    AccountGetWallets,
    AdminLogin,
    Index,
    TokenAll,
    TransactionCreate,
    UserGetWallets
  }

  @concurrency 1
  @sequence [
    Index,
    AdminLogin,
    UserGetWallets,
    TokenAll,
    AccountAll,
    AccountGetWallets,
    TransactionCreate
  ]

  def default_config, do: %{
    base_url: "http://localhost:4000"
  }

  def scenarios, do: [
    {{@concurrency, @sequence}, %{}}
  ]
end
