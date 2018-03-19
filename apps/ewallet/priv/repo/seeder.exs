defmodule EWallet.Seeder do
  @moduledoc """
  Script for populating the database.

  # Adding additional seeds

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
  alias EWallet.EmailValidator
  alias EWalletDB.Helpers.Crypto
  alias EWalletDB.Validator

  # The default email address to use for the first admin.
  @admin_email_default "admin@example.com"
  @admin_email_question """
    What email address should we set for your first admin user?
    This email is required for logging into the admin panel.
    If a user with this email already exists, it will escalate the user to admin role.
    """
  @admin_email_invalid """
    The given email address format is invalid. Please try seed again with a different email address.
    """

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

    # Ask for email address.
    # I really don't like to use `put_env` but it will do for now while we have not refactored
    # the seeding scripts into a proper structure.
    IO.puts(@admin_email_question)
    Application.put_env(:ewallet, :seed_admin_email, ask_email())
    Application.put_env(:ewallet, :seed_admin_password, ask_password())

    # Set the :env value so the code can determine if we allow seed to be run on this env or not
    Keyword.put_new(opts, :env, Application.get_env(:ewallet_db, :env))
  end

  defp ask_email do
    email =
      "E-mail (#{@admin_email_default}): "
      |> IO.gets()
      |> String.trim()

    cond do
      byte_size(email) == 0          -> @admin_email_default # use the default email if not provided
      EmailValidator.validate(email) -> email # use the given email if valid
      true                           -> CLI.halt(@admin_email_invalid) # else halt with error
    end
  end

  # Ask for a password and processes it
  defp ask_password do
    "Password (autogenerate if not given):"
    |> CLI.gets_sensitive()
    |> String.trim()
    |> process_password()
  end

  # Generate a password if not provided
  defp process_password(password) when byte_size(password) == 0 do
    Crypto.generate_key(16)
  end
  # Validate the password if provided. Halts if the format is invalid
  defp process_password(password) do
    case Validator.validate_password(password) do
      {:ok, password} ->
        password
      {:error, :too_short, data} ->
        CLI.halt("The password must be #{data[:min_length]} characters or more.")
    end
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

    if verbose?(opts) do
      CLI.heading("Verbose mode: Displaying seeded data")
    end

    # Run the minimum seed
    load(@init_seeds)
    Code.load_file("report_minimum.exs", __DIR__)

    # Run the sample seed if specified
    if sample_seed?(opts) do
      if verbose?(opts) do
        CLI.heading("Verbose mode: Displaying seeded sample data")
      end

      load(@sample_seeds)
      Code.load_file("report_sample.exs", __DIR__)
    end

    CLI.success("Database seeded completed. Enjoy!")
  end

  defp sample_seed?(opts), do: Keyword.get(opts, :sample, false)
  defp production?(opts), do: Keyword.get(opts, :env) == :prod
  defp verbose?(opts), do: Keyword.get(opts, :verbose, false)

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

  defmodule CLI do
    alias EWallet.CLI, as: EWalletCLI

    def subheading(message) do
      if Enum.member?(System.argv, "--verbose"), do: EWalletCLI.color([:light_black, message])
    end

    def info(message) do
      if Enum.member?(System.argv, "--verbose"), do: EWalletCLI.debug(message)
    end

    def success(message) do
      if Enum.member?(System.argv, "--verbose"), do: EWalletCLI.debug(message)
    end

    def warn(message) do
      if Enum.member?(System.argv, "--verbose"), do: EWalletCLI.debug(message)
    end

    def error(message), do: EWalletCLI.error(message)
  end
end

opts = EWallet.Seeder.init(System.argv)
EWallet.Seeder.call(opts)
