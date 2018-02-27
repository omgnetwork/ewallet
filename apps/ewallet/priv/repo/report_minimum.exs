alias EWallet.CLI

base_url       = Application.get_env(:ewallet_db, :base_url)
admin_api_url  = base_url <> "/admin/api"
login_url      = admin_api_url <> "/signin"
api_key_id     = Application.get_env(:ewallet, :seed_admin_api_key).id
api_key        = Application.get_env(:ewallet, :seed_admin_api_key).key
admin_email    = Application.get_env(:ewallet, :seed_admin_user).email
admin_password = Application.get_env(:ewallet, :seed_admin_user).password || "<password obscured>"

CLI.heading("Setting up the OmiseGO eWallet Server")

CLI.print("""
  This seeder seeds the minimum amount of data needed to start a production environment.

  In order to start using a fresh installation of the OmiseGO eWallet Server,
  you need to complete the following 3 steps:

  1. Configure the Admin Panel's .env file
  2. Login with the seeded Admin Panel user
  3. Populate data via the Admin Panel

  Note: If you would like to seed the database with sample data so you can
  play around with the system, we recommend running `mix seed --sample` instead.

  ## Step 1: Configure the Admin Panel's `.env` file

  We have just seeded the Admin Panel's API key for you. Copy & paste the following text
  to your Admin Panel's .env file:

  ```
  BASE_URL=#{admin_api_url}
  API_KEY_ID=#{api_key_id}
  API_KEY=#{api_key}
  ```

  ## Step 2: Login with the seeded Admin Panel user

  We have just seeded an Admin Panel user for you. Use the following credentials
  to login to your Admin Panel:

    - Login URL : `#{login_url}`
    - Email     : `#{admin_email}`
    - Password  : `#{admin_password}`

  ## Step 3: Populate data via the Admin Panel

  Now that you are logged in to the Admin Panel, you can:

  - Change your password immediately! The password will show in the seed only once.
  - Create other Admin Panel users
  - Manage access and secret keys for your application servers to connect to OmiseGO eWallet API
  - Manage API keys for your mobile apps and the Admin Panel
  - Always come back and access your Admin Panel at `#{admin_api_url}`
  - etc.

  *Database seeding completed. Enjoy!*
  """)
