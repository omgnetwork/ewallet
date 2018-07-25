# Upgrading

## Encryption Upgrade

Please note that starting June 19, 2018, we've switched the encryption scheme for metadata to AES-GCM rather than relying on libsodium. If you have existing data from previous releases, you must first upgrade the encryption scheme. This can be done in the following steps:

1.  Replace environment variable for encryption keys:

    -   Existing `EWALLET_SECRET_KEY` should be renamed to `RETIRED_EWALLET_SECRET_KEY`.
    -   Existing `LOCAL_LEDGER_SECRET_KEY` should be renamed to `RETIRED_LOCAL_LEDGER_SECRET_KEY`.

2.  Generate a new key with the following command:

    ```
    $ elixir -e "IO.puts 32 |> :crypto.strong_rand_bytes() |> Base.encode64()"
    ```

3.  Put the key in environment variables:

    -   `EWALLET_SECRET_KEY` for the new eWallet secret key.
    -   `LOCAL_LEDGER_SECRET_KEY` for the new local ledger secret key.

4.  Run the following command to migrate database and encryption keys:

    ```
    $ mix ecto.migrate
    $ mix omg.migrate.encryption
    ```
