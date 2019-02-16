# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWalletDB.Repo.Reporters.SeedsSampleReporter do
  alias EWalletConfig.Config

  def run(writer, args) do
    base_url = Config.get(:base_url)
    admin_api_swagger_ui_url = base_url <> "/api/admin/docs"
    ewallet_api_swagger_ui_url = base_url <> "/api/client/docs"

    admin_id = args[:seeded_admin_user_id]
    admin_auth_token = args[:seeded_admin_auth_token]

    ewallet_key_access = args[:seeded_ewallet_key_access]
    ewallet_key_secret = args[:seeded_ewallet_key_secret]
    ewallet_api_key = args[:seeded_ewallet_api_key]
    ewallet_auth_token = args[:seeded_ewallet_auth_token]

    writer.heading("Populating sample data")

    writer.print("""
    We have seeded some sample data for you to try the eWallet server out.
    You can play with the sample data right from the documentation by following
    the instructions below.

    ## Try out the Admin API

    1. Browse to `#{admin_api_swagger_ui_url}`
    2. Click the `Authorize` button
    3. Use the value below for `AdminAuth` (to authenticate you as an admin user):

    ```
    OMGAdmin #{Base.encode64(admin_id <> ":" <> admin_auth_token)}
    ```

    4. Use the value below for `ProviderAuth` (to authenticate you as a provider server):

    ```
    OMGProvider #{Base.encode64(ewallet_key_access <> ":" <> ewallet_key_secret)}
    ```

    5. See the sample data by trying out Admin API endpoints such as `/token.all`,
    `/exchange_pair.all`, `/transaction.create`, etc. right from the documentation.

    ## Try out the eWallet API

    1. Browse to `#{ewallet_api_swagger_ui_url}`
    2. Click the `Authorize` button
    3. Use the value below for `ClientAuth`:

    ```
    OMGClient #{Base.encode64(ewallet_api_key <> ":" <> ewallet_auth_token)}
    ```

    4. See the sample data by trying out eWallet API endpoints such as `/me.get_wallets`,
    `/me.get_settings`, `/me.get_transactions`, etc. right from the documentation.
    """)
  end
end
