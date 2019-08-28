# API Responsibilities

Integrating the OmiseGO eWallet requires a new setup to be deployed. Feel free to [get in touch](mailto:thibault@omisego.co) for that step as we offer hosted solutions. Before starting any integration, it is important to understand which responsibilities OmiseGO is taking care of and which ones you will need to implement.

## Responsibilities

### Features provided by the eWallet

These are examples of features provided by the OmiseGO eWallet. You may integrate with the APIs to utilize these features.

|Area of responsibilities|Tasks|
|------------------------|-----|
|Token management   | - Create loyalty tokens ([/token.create](https://ewallet.staging.omisego.io/api/admin/docs.ui#/Token/token_create)) <br> - Put more loyalty tokens in circulation ([/token.mint](https://ewallet.staging.omisego.io/api/admin/docs.ui#/Token/token_mint)) <br> - Update loyalty token information ([/token.update](https://ewallet.staging.omisego.io/api/admin/docs.ui#/Token/token_update)) <br> - Provide user interface for creating new loyalty tokens (Admin Panel) <br> - Provide user interface for add/remove of loyalty tokens from circulation (Admin Panel)|
|Secondary user store|- Create users along with their wallets ([/user.create](https://ewallet.staging.omisego.io/api/admin/docs.ui#/User/user_create))|
|Transactions|- List all transactions ([/transaction.all](https://ewallet.staging.omisego.io/api/admin/docs.ui#/Transaction/transaction_all)) <br>- Perform credit/debit of loyalty tokens to/from users ([/transaction.create](https://ewallet.staging.omisego.io/api/admin/docs.ui#/Transaction/transaction_create))|
|Entity management|- Create, update and list accounts ([/account.create](https://ewallet.staging.omisego.io/api/admin/docs.ui#/Account/account_create), [/account.update](https://ewallet.staging.omisego.io/api/admin/docs.ui#/Account/account_update), [/account.all](https://ewallet.staging.omisego.io/api/admin/docs.ui#/Account/account_all))<br>- Create, update and list users with their wallets ([/user.create](https://ewallet.staging.omisego.io/api/admin/docs.ui#/User/user_create), [/user.update](https://ewallet.staging.omisego.io/api/admin/docs.ui#/User/user_update), [/user.all](https://ewallet.staging.omisego.io/api/admin/docs.ui#/User/user_all))<br>- Assign and unassign roles to users in an account ([/account.assign_user](https://ewallet.staging.omisego.io/api/admin/docs.ui#/Account/account_assign_user), [/account.unassign_user](https://ewallet.staging.omisego.io/api/admin/docs.ui#/Account/account_unassign_user))|
|API management|- Generate and invalidate access and secret keys for server application ([/access_key.create](https://ewallet.staging.omisego.io/api/admin/docs.ui#/API%20access/access_key_create), [/access_key.delete](https://ewallet.staging.omisego.io/api/admin/docs.ui#/API%20access/access_key_delete))<br>- Generate and invalidate API keys for mobile application ([/api_key.create](https://ewallet.staging.omisego.io/api/admin/docs.ui#/API%20access/api_key_create), [/api_key.delete](https://ewallet.staging.omisego.io/api/admin/docs.ui#/API%20access/api_key_delete))|
|Payment request|- Generate payment requests with QR code ([Transaction Request Flow](transaction_request_flow.md))|
|Notifications|- Notify merchant panel user of new successful payments ([eWallet API Websockets](ewallet_api_websockets.md))|

### Provider's side

These are examples of features that are out of scope of the OmiseGO eWallet. You will need to consider implementing these features into your application.

See the attached links for examples on how to implement these features in your application.

|Side|Area of responsibilities|Tasks|
|----|------------------------|-----|
|Server|User management|- Create and safely store end-user data (e.g. [User](https://github.com/omisego/sample-server/blob/master/app/models/user.rb))<br>- Send user creation requests to eWallet API (e.g. [Signup](https://github.com/omisego/sample-server/blob/master/app/services/signup.rb))<br>- Maintain the immutable user identifier (provider_user_id) to identify a user in eWallet API (e.g. [Signup](https://github.com/omisego/sample-server/blob/master/app/services/signup.rb#L34), [Login](https://github.com/omisego/sample-server/blob/master/app/services/login.rb#L24), [Purchaser](https://github.com/omisego/sample-server/blob/master/app/services/purchaser.rb#L54))|
|Server|Mobile app authentication|- Authenticate mobile application user (e.g. [Authenticator](https://github.com/omisego/sample-server/blob/master/app/services/authenticator.rb))<br>- Request authentication tokens from eWallet API and send to the client application (e.g. [TokenGenerator](https://github.com/omisego/sample-server/blob/master/app/services/login.rb))|
|Server|Transactions (read/write)|- Perform credit and debit calls to eWallet API (e.g. [Purchaser](https://github.com/omisego/sample-server/blob/master/app/services/purchaser.rb))<br>- Perform all other data-changing operations with eWallet API|
|Mobile   |User management   |  - Register new user with the server application (e.g. [iOS](https://github.com/omisego/sample-ios/blob/master/OMGShop/Managers/SessionManager.swift), [Android](https://github.com/omisego/sample-android/blob/master/app/src/main/java/co/omisego/omgshop/pages/register/RegisterActivity.kt))<br>- Send user data updates to the server application|
|Mobile   |User authentication   | - Authenticate user with the server application (e.g. [iOS](https://github.com/omisego/sample-ios/blob/master/OMGShop/API/Models/SessionAPI.swift), [Android](https://github.com/omisego/sample-android/blob/master/app/src/main/java/co/omisego/omgshop/pages/login/LoginActivity.kt))<br>- Retrieve and store eWallet API’s authentication token from the server application (e.g. [iOS](https://github.com/omisego/sample-ios/blob/master/OMGShop/Managers/SessionManager.swift), [Android](https://github.com/omisego/sample-android/blob/master/app/src/main/java/co/omisego/omgshop/pages/login/LoginActivity.kt))|
|Mobile   |Transactions (read-only)  | - Retrieve user wallets from the eWallet API<br>- Retrieve the list of settings including supported tokens (e.g. [iOS](https://github.com/omisego/sample-ios/blob/master/OMGShop/Managers/TokenManager.swift), [Android](https://github.com/omisego/sample-android/blob/master/app/src/main/java/co/omisego/omgshop/pages/checkout/CheckoutActivity.kt))<br>- All data-changing operations cannot be performed by the mobile application|
