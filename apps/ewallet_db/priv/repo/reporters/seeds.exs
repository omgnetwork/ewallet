defmodule EWalletDB.Repo.Reporters.SeedsReporter do
  def run(writer, args) do
    base_url = Application.get_env(:ewallet_db, :base_url) || "https://example.com"
    admin_panel_url = base_url <> "/admin"
    admin_api_swagger_ui_url = base_url <> "/api/admin/docs"
    ewallet_swagger_ui_url = base_url <> "/api/client/docs"

    admin_id = args[:seeded_admin_user_id]
    admin_email = args[:seeded_admin_user_email]
    admin_password = args[:seeded_admin_user_password]
    admin_auth_token = args[:seeded_admin_auth_token]
    admin_api_key = args[:seeded_admin_api_key]
    admin_api_key_id = args[:seeded_admin_api_key_id]

    writer.heading("Setting up the OmiseGO eWallet Server")
    writer.print("""
    This seeder seeds the minimum amount of data needed to start a production environment.

    If you would like to seed the database with sample data so that you can
    play around with the system, we recommend running `mix seed --sample` instead.

    ## Manage your eWallet system via the Admin Panel

    We have just seeded your eWallet system with an API key and an Admin Panel user.
    Now it's your turn to login to your Admin Panel with the following credentials:

    - Login URL : `#{admin_panel_url}`
    - Email     : `#{admin_email}`
    - Password  : `#{admin_password}`

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

             OMGAdmin #{Base.encode64(admin_api_key_id <> ":" <> admin_api_key)}

       Note: You can also make requests from your favorite API client
       by building your own Authorization header:

       - Authorization header : OMGAdmin base64(api_key_id:api_key)
       - API key ID           : #{admin_api_key_id}
       - API key              : #{admin_api_key}

    3. Now you can call the `/login` endpoint with the above Authorization header
       and the following request body:

             {
               "email": "#{admin_email}",
               "password": "#{admin_password}"
             }

       _Please take note of the above password._ We won't be able to retrieve it again
       after the initial seed, as it will be one-way encrypted for your security.

    4. To get started quickly, we have seeded the user's authentication token
       and generated the Authorization header for you. Browse to #{admin_api_swagger_ui_url}
       again and click Authorize. This time, use the value below for UserAuth:

             OMGAdmin #{Base.encode64(admin_api_key_id <> ":" <> admin_api_key <> ":" <> admin_id <> ":" <> admin_auth_token)}

       The above header is for you to get started quickly. To integrate the eWallet SDK
       to your application, you must build your own Authorization header using the information below:

       - Authorization header : `OMGAdmin base64(api_key_id:api_key:user_id:auth_token)`
       - API key ID           : `#{admin_api_key_id}`
       - API key              : `#{admin_api_key}`
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
    """)
  end
end
