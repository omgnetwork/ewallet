defmodule LoadTester.Runner do
  use Chaperon.LoadTest
  alias LoadTester.Scenarios.{
    AccountAll,
    AccountCreate,
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
    AccountCreate,
    TransactionCreate
  ]

  def default_config, do: %{
    base_url:
      Application.get_env(:load_tester, :loadtest_protocol)
      <> "://" <> Application.get_env(:load_tester, :loadtest_host)
      <> ":" <> Application.get_env(:load_tester, :loadtest_port)
  }

  def scenarios, do: [
    {{@concurrency, @sequence}, %{}}
  ]
end
