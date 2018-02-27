defmodule EWallet.Seeder do
  @moduledoc """
  Script for populating the database.

  # Usage

  You can run the seed through mix alias on the root umbrella app folder:

  ```
  mix seed
  ```

  Or run the seed directly:

  ```
  mix run apps/ewallet/priv/repo/seeds.exs
  ```

  To do a full seed (useful for dev environment), pass the `--full` flag.

  ```
  mix seed --full
  ```

  The `--full` flag is useful when you are starting from scratch
  and would like to have as much seed data populated as possible.

  # Additional seeds

  To add more types of seeds, simply create a new seed file,
  then append the file name to either `@init_seeds` or `@full_seeds` below.

  # Seeding script

  Inside each seed file, you can seed the entity by calling
  the schema's insert function:

  ```
  EWalletDB.SomeSchema.insert(a_data_map)
  ```

  Direct repo insert, e.g. `EWalletDB.Repo.insert!` should be avoided because
  it does not preserve data integrity implemented in the schema.
  """
  alias EWallet.CLI

  # Seeds to intialize the system.
  @init_seeds [
    "initial_account.exs",
    "initial_api_key.exs",
    "initial_role.exs",
    "initial_user.exs"
  ]

  # Seeds to populate the database with sample data. This is useful for development
  # and testing environments, but not recommended for production environment.
  # The seeds will be executed in the order of this list.
  @sample_seeds [
    "account.exs",
    "minted_token.exs",
    "user.exs",
    "admin.exs",
    "key.exs",
    "api_key.exs",
    "auth_token.exs"
  ]

  # The path to the folder that contains the actual seeding scripts.
  @seed_folder __DIR__ <> "/seeders"

  @doc """
  Processes the call arguments.
  """
  def init(args) do
    {opts, _argv, _errors} = OptionParser.parse(args)
    Keyword.put_new(opts, :env, Application.get_env(:ewallet_db, :env))
  end

  @doc """
  Executes the seeders.
  """
  def call(opts) do
    if sample_seed?(opts) && production?(opts) do
      CLI.halt("The sample seed cannot be run on :prod environment!")
    end

    # Disable noisy debug messages. Seeders already have their own log messages.
    Logger.configure(level: :warn)

    # Run the seed
    unless sample_seed?(opts) do
      load(@init_seeds)
      Code.load_file("report_minimum.exs", __DIR__)
    else
      load(@init_seeds)
      load(@sample_seeds)
      Code.load_file("report_sample.exs", __DIR__)
    end
  end

  defp sample_seed?(opts), do: Keyword.get(opts, :sample, false)
  defp production?(opts), do: Keyword.get(opts, :env) == :prod

  defp load(files) do
    Enum.each(files, fn(file) ->
      Code.load_file(file, @seed_folder)
    end)
  end

  def print_errors(%{errors: errors}) do
    Enum.each(errors, fn({field, {message, _}}) ->
      CLI.error("  `#{field}` #{message}")
    end)
  end
end

opts = EWallet.Seeder.init(System.argv)
EWallet.Seeder.call(opts)
