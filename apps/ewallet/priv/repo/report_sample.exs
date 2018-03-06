alias EWallet.CLI

base_url            = Application.get_env(:ewallet_db, :base_url)

# eWallet API
ewallet_swagger_ui_url = base_url <> "/api/swagger"
ewallet_key         = Application.get_env(:ewallet, :seed_ewallet_key)
ewallet_api_key     = Application.get_env(:ewallet, :seed_ewallet_api_key)
ewallet_auth_token  = Application.get_env(:ewallet, :seed_ewallet_auth_token)

# Admin API
admin_api_swagger_ui_url = base_url <> "/admin/api/swagger"
admin_api_key         = Application.get_env(:ewallet, :seed_admin_api_key)
admin_user            = Application.get_env(:ewallet, :seed_admin_user)
admin_auth_token      = Application.get_env(:ewallet, :seed_admin_auth_token)

CLI.heading("Trying out OmiseGO eWallet Server with sample data")

CLI.print("""
  This seeder seeds numerous sample data so that after the seed,
  you can use our Swagger UI to freely play around with the complete
  set of OmiseGO eWallet applications:

  - `eWallet API`'s Server endpoints
  - `eWallet API`'s Client endpoints
  - `Admin API`'s Client endpoints
  - `Admin API`'s User endpoints

  If you would like to seed the database with the minimum amount needed to start
  a production environment, we recommend running `mix seed` instead.

  ## Try eWallet API's Server endpoints

  1. Browse to `#{ewallet_swagger_ui_url}`
  2. Click the `Authorize` button
  3. Use the value below for `ServerAuth`:

  ```
  OMGServer #{Base.encode64(ewallet_key.access_key <> ":" <> ewallet_key.secret_key)}
  ```

  4. Try out Server endpoints such as /login, /user.create, /transfer, etc.

  ## Try eWallet API's Client endpoints

  1. Browse to `#{ewallet_swagger_ui_url}`
  2. Click the `Authorize` button
  3. Use the value below for `ClientAuth`:

  ```
  OMGClient #{Base.encode64(ewallet_api_key.key <> ":" <> ewallet_auth_token)}
  ```

  4. Try out Client endpoints such as /me.get, /me.list_transactions, /logout, etc.

  ## Try Admin API's Client endpoints

  1. Browse to `#{admin_api_swagger_ui_url}`
  2. Click the `Authorize` button
  3. Use the value below for `ClientAuth`:

  ```
  OMGAdmin #{Base.encode64(admin_api_key.id <> ":" <> admin_api_key.key)}
  ```

  4. Try out Client endpoints such as /login, /password.reset, /password.update, etc.

  ## Try Admin API's User endpoints

  1. Browse to `#{admin_api_swagger_ui_url}`
  2. Click the `Authorize` button
  3. Use the value below for `UserAuth`:

  ```
  OMGAdmin #{Base.encode64(admin_api_key.id <> ":" <> admin_api_key.key <> ":" <> admin_user.id
    <> ":" <> admin_auth_token)}
  ```

  4. Try out User endpoints such as /account.create, /account.assign_user, /access_key.create, etc.

  *Database seeded with sample data. Enjoy!*
  """)
