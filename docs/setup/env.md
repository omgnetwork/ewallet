# Environment Variables

## General

Below are the general environment variables needed for the eWallet to run smoothly.

- `MIX_ENV`: Environment in which the application is being ran. `prod` for production.
- `BASE_URL`: The base to use when building URLs.
- `PORT`: The port that the application listens on.
- `EWALLET_SECRET_KEY`: Encryption key used to encrypt some data in the database.
- `LOCAL_LEDGER_SECRET_KEY`: Encryption key used to encrypt some data in the database.

Tip: How to generate a new secret key using Elixir:

```
$ mix run -e "IO.puts Salty.SecretBox.generate_key()"
8I_xIED7p7ruxxM1vNiWzsud3DALk0cnpcAncC2YyMs
```

## Database

The eWallet needs access to two different databases: one for the eWallet itself and one for the local ledger. The following environment variables needs to be set.

- `DATABASE_URL`
- `LOCAL_LEDGER_DATABASE_URL`

## Error Reporting

The eWallet only supports [Sentry](https://sentry.io/welcome/) for now. You can specify the DSN for it with the following environment variable:

- `SENTRY_DSN`

## Balance Caching

The local ledger offers a caching mechanism for balances in order to boost the calculation speed (in case you have millions of transactions). To enable this feature, set the `BALANCE_CACHING_FREQUENCY` environment variable and pass it a valid CRON schedule. Note that this is totally optional and the application will work fine without it.

- `BALANCE_CACHING_FREQUENCY`: A valid CRON schedule.

Examples:

- Every minute:         `"* * * * *"`
- Every day at 2 am:    `"0 2 * * *"`
- Every Friday at 5 am: `"0 5 * * 5"`

If this feature is enabled, you can also specify a caching strategy.

- `BALANCE_CACHING_STRATEGY`: Specify if new cached balances should be computed using a previous cache or by recalculating everything from scratch.

Strategies available:

- `since_beginning`: Recalculate the balance since the beginning of time.
- `since_last_cached`: Use the last cached balance, adds the transactions that happened since and saves the result in a new cached balance.

## Emails

To enable emails in the eWallet (for forget password or inviting admins), you'll need to set the following environment variables:

- `SMTP_HOST`: Your email server domain name.
- `SMTP_PORT`: The port used to connect to your email server.
- `SMTP_USER`: Identifier to use your email server.
- `SMTP_PASSWORD`: Password for email server.

## File Upload

- `FILE_STORAGE_ADAPTER`: (`local`|`aws`|`gcs`, defaults to `local`)

In order to use the file upload feature (for profile pictures and account logos), environment variables need to be defined.

### Local File Storage

Nothing else to set, files will be stored at the root of the project in `public/uploads/`.

### Amazon S3

- `AWS_BUCKET`: The name of your S3 bucket.
- `AWS_REGION`: The region in which your bucket lives.
- `AWS_ACCESS_KEY_ID`: Your AWS access key.
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key.

### Google Cloud Storage

- `GCS_BUCKET`: Your GCS bucket.
- `GCS_CREDENTIALS`: A JSON containing your GCS credentials.
