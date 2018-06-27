defmodule EWalletDB.Repo.Reporters.SeedsSampleReporter do
  def run(writer, args) do
    base_url = Application.get_env(:ewallet_db, :base_url) || "https://example.com"
    admin_api_swagger_ui_url = base_url <> "/api/admin/docs"
    ewallet_swagger_ui_url = base_url <> "/api/client/docs"

    admin_id = args[:seeded_admin_user_id]
    admin_auth_token = args[:seeded_admin_auth_token]
    admin_api_key = args[:seeded_admin_api_key]
    admin_api_key_id = args[:seeded_admin_api_key_id]

    ewallet_key_access = args[:seeded_ewallet_key_access]
    ewallet_key_secret = args[:seeded_ewallet_key_secret]
    ewallet_api_key = args[:seeded_ewallet_api_key]
    ewallet_auth_token = args[:seeded_ewallet_auth_token]

    writer.heading("Trying out OmiseGO eWallet Server with sample data")
    writer.print("""
    As you have just run the seed with `--sample` option, we have generated some credentails below
    for you to try the endpoints easily.

    If you would like to seed the database with the minimum amount needed to start
    a production environment, we recommend running `mix seed` instead.

    ## Try eWallet API's Server endpoints

    1. Browse to `#{ewallet_swagger_ui_url}`
    2. Click the `Authorize` button
    3. Use the value below for `ServerAuth`:

    ```
    OMGProvider #{Base.encode64(ewallet_key_access <> ":" <> ewallet_key_secret)}
    ```

    4. Try out Server endpoints such as /login, /user.create, etc.

    ## Try eWallet API's Client endpoints

    1. Browse to `#{ewallet_swagger_ui_url}`
    2. Click the `Authorize` button
    3. Use the value below for `ClientAuth`:

    ```
    OMGClient #{Base.encode64(ewallet_api_key <> ":" <> ewallet_auth_token)}
    ```

    4. Try out Client endpoints such as /me.get, /me.list_transactions, /me.logout, etc.

    ## Try Admin API's Client endpoints

    1. Browse to `#{admin_api_swagger_ui_url}`
    2. Click the `Authorize` button
    3. Use the value below for `ClientAuth`:

    ```
    OMGAdmin #{Base.encode64(admin_api_key_id <> ":" <> admin_api_key)}
    ```

    4. Try out Client endpoints such as /login, /password.reset, /password.update, etc.

    ## Try Admin API's User endpoints

    1. Browse to `#{admin_api_swagger_ui_url}`
    2. Click the `Authorize` button
    3. Use the value below for `UserAuth`:

    ```
    OMGAdmin #{Base.encode64(admin_api_key_id <> ":" <> admin_api_key <> ":" <> admin_id <> ":" <> admin_auth_token)}
    ```

    4. Try out User endpoints such as /account.create, /account.assign_user, /access_key.create, etc.
    """)
  end
end
