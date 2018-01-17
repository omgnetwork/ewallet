defmodule LocalLedgerMQ.Mixfile do
  use Mix.Project

  def project do
    [
      app: :local_ledger_mq,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env)
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:sentry, :logger, :amqp],
      mod: {LocalLedgerMQ.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rabbitmq_rpc, git: "ssh://git@github.com/omisego/rabbitmq-rpc.git",
                       tag: "0.3.0"},
      {:sentry, "~> 6.0.0"},
      {:local_ledger, in_umbrella: true}
    ]
  end

  # This makes sure your factory and any other modules in test/support are
  # compiled when in the test environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
