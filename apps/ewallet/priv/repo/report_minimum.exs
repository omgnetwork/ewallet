alias EWallet.CLI
alias EWalletDB.AuthToken

# Prepare URLs
base_url                 = Application.get_env(:ewallet_db, :base_url)
admin_panel_url          = base_url <> "/admin"
ewallet_swagger_ui_url   = base_url <> "/api/swagger"
admin_api_swagger_ui_url = base_url <> "/admin/api/swagger"

# Prepare the seeded data
api_key_id              = Application.get_env(:ewallet, :seed_admin_api_key).id
api_key                 = Application.get_env(:ewallet, :seed_admin_api_key).key
admin                   = Application.get_env(:ewallet, :seed_admin_user)
{:ok, admin_auth_token} = AuthToken.generate(admin, :admin_api)

# Prepare admin_panel's `.env` file
dotenv_path = "apps/admin_panel/assets/.env"
File.cwd!
|> Path.join(dotenv_path)
|> File.write!("""
  ADMIN_API_KEY_ID=#{api_key_id}
  ADMIN_API_KEY=#{api_key}
  """)

# Output the seeding result
CLI.heading("Setting up the OmiseGO eWallet Server")

CLI.print("""
  This seeder seeds the minimum amount of data needed to start a production environment.

  If you would like to seed the database with sample data so that you can
  play around with the system, we recommend running `mix seed --sample` instead.

  ## Manage your eWallet system via the Admin Panel

  We have just seeded your eWallet system with an API key and an Admin Panel user.
  To save your time, we have also configured the Admin Panel with the seeded API key.
  If you want to, you can look up the configuration file at `#{dotenv_path}`.

  Now it's your turn to login to your Admin Panel with the following credentials:

    - Login URL : `#{admin_panel_url}`
    - Email     : `#{admin.email}`
    - Password  : `#{admin.password || "<password obscured>"}`

  _Please take note of the above password._ We won't be able to retrieve it again
  after the initial seed, as it will be one-way encrypted for your security.

  Now that you are logged in to the Admin Panel, you can:

    - Change your password immediately! The password will show in the seed only once.
    - Create other Admin Panel users
    - Manage access and secret keys for your application servers to connect to OmiseGO eWallet API
    - Manage API keys for your mobile apps and the Admin Panel
    - Always come back and access your Admin Panel at #{admin_panel_url}
    - etc.

  ## Manage your eWallet system via the Admin API

  The Admin API is the entry point to manage the entire OmiseGO eWallet system.
  Follow the steps below to authenticate your Swagger UI requests:

    1. Browse to `#{admin_api_swagger_ui_url}` and click `Authorize`
    2. Use the value below for `ClientAuth` and click `Authorize`:

      ```
      OMGAdmin #{Base.encode64(api_key_id <> ":" <> api_key)}
      ```

      Note: You can also make requests from your favorite API client
      by building your own Authorization header:

        - Authorization header : OMGAdmin base64(api_key_id:api_key)
        - API key ID           : #{api_key_id}
        - API key              : #{api_key}

    3. Now you can call the `/login` endpoint with the above Authorization header
    and the following request body:

      ```
      {
        "email": "#{admin.email}",
        "password": "#{admin.password || "<password obscured>"}"
      }
      ```

      _Please take note of the above password._ We won't be able to retrieve it again
      after the initial seed, as it will be one-way encrypted for your security.

    4. To get started quickly, we have seeded the user's authentication token
      and generated the Authorization header for you. Browse to #{admin_api_swagger_ui_url}
      again and click Authorize. This time, use the value below for UserAuth:

      ```
      OMGAdmin #{Base.encode64(api_key_id <> ":" <> api_key
        <> ":" <> admin.id <> ":" <> admin_auth_token)}
      ```

      The above header is for you to get started quickly. To integrate the eWallet SDK
      to your application, you must build your own Authorization header using the information below:

        - Authorization header : `OMGAdmin base64(api_key_id:api_key:user_id:auth_token)`
        - API key ID           : `#{api_key_id}`
        - API key              : `#{api_key}`
        - User ID              : `<the returned user_id in step 3>`
        - User's auth token    : `<the returned authentication_token in step 3>`

    5. Test your authentication by calling `/me.get`. You should see your user information.

  ## Using the eWallet API

  Now that you are authenticated, you have the full access to the eWallet system via the Admin API.
  You can now use the Authorization header above with the rest of the Swagger specification at
  `#{admin_api_swagger_ui_url}` to:

  - Generate a pair of access/secret key for your application servers via `/access_key.create`
  - Generate a pair of API key for your clients such as your mobile app, via `/api_key.create`
  - Use the API key generated above to make requests to the eWallet API.
    Learn more at `#{ewallet_swagger_ui_url}`
  - etc.

  *Database seeding completed. Enjoy!*
  """)
