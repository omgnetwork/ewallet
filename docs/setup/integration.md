# Integrating the OmiseGO SDK

Integrating the OmiseGO eWallet requires a new setup to be deployed. Feel free to [get in touch](mailto:thibault@omisego.co) for that step as we offer hosted solutions. Before starting any integration, it is important to understand which responsibilities OmiseGO is taking care of and which ones you will need to implement.

## Responsibilities

### Features provided by the SDK

|Area of responsibilities|Tasks|
|------------------------|-----|
|Token management   | - Create loyalty tokens <br> - Put more loyalty tokens in circulation <br> - Remove loyalty tokens from circulation <br> - Provide user interface for creating new loyalty tokens <br> - Provide user interface for add/remove of loyalty tokens from circulation|
|Secondary user store|- Create users along with their token balances. The user stored in the Wallet API is solely for identifying and transacting with the user’s token balances.|
|Token transactions|- Perform credit/debit of loyalty tokens to/from users|
|Entity management|- Create, update and list accounts<br>- Create, update and list users with their balances<br>- Assign and unassign roles to users in an account<br>- Assign and unassign permissions to roles|
|API management|- Generate and invalidate access and secret keys (for server application)<br>- Generate and invalidate API keys (for mobile application)|
|Transactions|- List all transactions and their credit/debit entries|
|Payment request|- Generate payment requests with QR code|
|Notifications|- Notify merchant panel user of new successful payments|

### Provider's side

|Side|Area of responsibilities|Tasks|
|----|------------------------|-----|
|Server|User management|- Create and safely store end-user data<br>- Send user creation requests to eWallet API (only to interact with their balances)<br>- Maintain the immutable user identifier (provider_user_id) to identify a user in eWallet API|
|Server|Mobile app authentication|- Authenticate mobile application user<br>- Request authentication tokens from eWallet API and send to the client application|
|Server|Transactions (read/write)|- Perform credit and debit calls to eWallet API<br>- Perform all other data-changing operations with eWallet API|
|Mobile   |User management   |  - Register new user with the server application<br>- Send user data updates to the server application|
|Mobile   |User authentication   | - Authenticate user with the server application<br>- Retrieve and store eWallet API’s authentication token from the server application|
|Mobile   |Transactions (read-only)  | - Retrieve user balances from the eWallet API<br>- Retrieve the list of settings including supported tokens.<br>- All data-changing operations cannot be performed by the mobile application|
