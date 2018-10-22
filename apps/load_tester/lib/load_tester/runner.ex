defmodule LoadTester.Runner do
  use Chaperon.LoadTest

  alias LoadTester.Scenarios.{
    AccountAll,
    AccountCreate,
    AccountGetWallets,
    AdminLogin,
    Index,
    TokenAll,
    TokenCreate,
    TransactionCreate,
    UserGetWallets
  }

  @concurrency 1
  @sequence [
    Index,
    AdminLogin,
    UserGetWallets,
    TokenAll,
    TokenCreate,
    AccountAll,
    AccountCreate,
    AccountGetWallets,
    TransactionCreate
  ]

  def default_config,
    do: %{
      base_url:
        Application.get_env(:load_tester, :protocol) <>
          "://" <>
          Application.get_env(:load_tester, :host) <>
          ":" <> Application.get_env(:load_tester, :port)
    }

  def scenarios,
    do: [
      {{@concurrency, @sequence}, %{}}
    ]
end
