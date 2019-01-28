# Settings

Settings allow you to configure system-wide behavior of the eWallet server. All settings are configurable via the Admin Panel.

## General

Below are the general settings needed for the eWallet to run.

- `base_url`: The base to use when building URLs.

## Incoming Requests

The eWallet allows you to configure different aspects of the incoming requests.
We try to provide sane default values, but if needed, the following settings are configurable:

- `max_per_page`: The maximum value of `per_page` a request can make. This helps prevent requests from overloading the system by sending a very high `per_page` value.

## Standalone eWallet

The eWallet is able to work independent of an external integration. The default configurations expect the eWallet to be integrated with another system, but the following settings can be configured:

- `enable_standalone`: Enables standalone mode such as `/api/client/user.signup`, `/api/client/user.verify_email` and `/api/client/user.login` so that the eWallet can be used without integration with other systems. Set to `true` to enable the feature.

## User authentication

- `min_password_length`: The minimum length of the password that a user is allowed to set.
- `forget_password_request_lifetime`: The duration (in minutes) that a forget password request will be valid for.

## External Redirects

Some features such as email verification allows redirects to URIs external to the eWallet. For security reasons we do not allow redirects to arbitary URIs, unless the prefix is whitelisted.

- `redirect_url_prefixes`: A comma-separated list of prefixes that are allowed to be redirected to. For example, setting the value to `https://example.com,pos-client://example.com` allows redirects to `https://example.com/some_url` and `pos-client://example.com/some_deep_linked_url`.

## Balance Caching

The local ledger offers a caching mechanism for wallets in order to boost the calculation speed (in case you have millions of transactions).

- `balance_caching_strategy`: Specify if new cached wallets should be computed using a previous cache or by recalculating everything from scratch.

  Strategies available:
  - `since_beginning`: Recalculate the balance since the beginning of time.
  - `since_last_cached`: Use the last cached balance, adds the transactions that happened since and saves the result in a new cached balance.


- `balance_caching_reset_frequency`: Specify that a cached balance needs to be recalculated at the n<sup>th</sup> time of usage when using a `since_last_cached` caching strategy. Setting this to 0 means that cached balances will never be re-calculated from the beginning.

## Emails

To enable emails in the eWallet (for forget password or inviting admins), you'll need to set the following settings:

- `sender_email`: The email address to appear as the sender.
- `email_adapter`: The adapter to use for sending emails. (`local`|`test`|`smtp`, defaults to `local`)

### SMTP Adapter

- `smtp_host`: Your email server domain name.
- `smtp_port`: The port used to connect to your email server.
- `smtp_user`: Identifier to use your email server.
- `smtp_password`: Password for email server.

## File Upload

- `file_storage_adapter`: (`local`|`aws`|`gcs`, defaults to `local`)

In order to use the file upload feature (for profile pictures and account logos), the following settings need to be defined.

### Amazon S3

- `aws_bucket`: The name of your S3 bucket.
- `aws_region`: The region in which your bucket lives.
- `aws_access_key_id`: Your AWS access key.
- `aws_secret_access_key`: Your AWS secret key.

### Google Cloud Storage

- `gcs_bucket`: Your GCS bucket.
- `gcs_credentials`: A JSON containing your GCS credentials.
