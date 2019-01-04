# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWalletDB.Repo.Reporters.SeedsReporter do
  alias EWalletConfig.Config

  def run(writer, args) do
    base_url = Config.get("base_url", "https://example.com")
    admin_panel_url = base_url <> "/admin"
    admin_api_url = base_url <> "/api/admin"
    admin_api_swagger_ui_url = base_url <> "/api/admin/docs"

    admin_email = args[:seeded_admin_user_email]
    admin_password = args[:seeded_admin_user_password]
    access_key = args[:seeded_ewallet_key_access]
    secret_key = args[:seeded_ewallet_key_secret]

    writer.heading("Setting up the OmiseGO eWallet Server")
    writer.print("""
    We have seeded the minimum amount of data for you to start a production environment.
    You may begin using your OmiseGO eWallet Server in 2 easy steps:

    ## 1. Manage your eWallet system with the Admin Panel

    To start using the Admin Panel, login with the following credentials:

      - Login URL : `#{admin_panel_url}`
      - Email     : `#{admin_email}`
      - Password  : `#{admin_password}`

    _Please take note of the above password_ and change it immediately after login.
    After the first seed, we won't be able to retrieve it again, and will be shown above
    as <hidden>.

    ## 2. Integrate your server application with the Admin API

    Each time the seed is run, we create a new pair of access and secret keys for you.
    Setup the following credentials in your server application to create your first
    authenticated request.

      - Base URL      : `#{admin_api_url}`
      - Authorization : `OMGProvider base64(access_key:secret_key)`
      - Access key    : `#{access_key}`
      - Secret key    : `#{secret_key}`

    Learn about all Admin API endpoints at `#{admin_api_swagger_ui_url}`.
    """)
  end
end
