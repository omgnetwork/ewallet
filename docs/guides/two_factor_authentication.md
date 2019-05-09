# Two-factor Authentication

Two-factor authentication provides an extra layer of security for admin users by using, as the name suggests, an additional factor in the login process (a time-based one-time usage passcode, in addition to the usual email/password pair).

This guide will provide a brief explanation to understand how the two-factor authentication system works in the eWallet.

## Table of Contents

- [Two-factor Authentication](#two-factor-authentication)
  - [Table of Contents](#table-of-contents)
    - [Enable 2FA](#enable-2fa)
      - [Create a Secret Code](#create-a-secret-code)
      - [Create Backup Codes](#create-backup-codes)
    - [Log in with 2FA](#log-in-with-2fa)
    - [Disable 2FA](#disable-2fa)
    - [Note](#note)

### Enable 2FA

To enable two-factor authentication, a secret code must be provided. This secret code is generated through an endpoint of the eWallet. The section below will explain how to get one.

#### Create a Secret Code

The secret code is a unique 16 character alphanumeric code used to create the time-based one-time passcodes (each generated code will only be valid for x seconds).

To create a secret code, call to `/me.create_secret_code` with the appropriate parameters:

```bash
curl http://localhost:4000/api/admin/me.create_secret_code \
-X POST \
-H "Accept: application/vnd.omisego.v1+json" \
-H "Authorization: OMGAdmin $(echo -n "user_id:auth_token" | base64 | tr -d '\n')" \
-H "Content-Type: application/json" \
-d '{}' \
-v -w "\n" | jq
```

The response will be similar to:

```json
{
  "version": "1",
  "success": true,
  "data": {
    "secret_2fa_code": "EDK4WLQ2A5DXYFAL",
    "object": "secret_code",
    "label": "user@example.com",
    "issuer": "OmiseGO"
  }
}
```

We can now create a two-factor QR code by using the data received in this response.

**Try:** use a web service to quickly generate a two-factor QR code e.g. [Stefan Sundin's 2FA QR code generator](https://stefansundin.github.io/2fa-qr/)

Then use a TOTP (time-based one-time password) application such as Authy or Google Authenticator to scan that QR code.

The 6-digits passcode should be now displayed on the application.

Next, we highly recommend creating backup codes that can be used to recover access to your account if you lose your 2FA device.

#### Create Backup Codes

Backup codes are a set of codes that can be used for two-factor authentication in case you don't have access to the TOTP anymore. To create backup codes, call the endpoint `/me.create_backup_codes` as shown below:

```bash
curl http://localhost:4000/api/admin/me.create_backup_codes \
-X POST \
-H "Accept: application/vnd.omisego.v1+json" \
-H "Authorization: OMGAdmin $(echo -n "user_id:auth_token" | base64 | tr -d '\n')" \
-H "Content-Type: application/json" \
-d '{}' \
-v -w "\n" | jq
```

The response will look something like this:

```json
{
  "version": "1",
  "success": true,
  "data": {
    "object": "backup_codes",
    "backup_codes": [
      "44eba8a0",
      "b70fbcb5",
      "891b195f",
      "fcc6566d",
      "2508c78c",
      "7250399f",
      "ae4905db",
      "d6dd6568",
      "0a555b84",
      "1bd686ce"
    ]
  }
}
```

Finally, call `/me.enable_2fa` with the following parameters:

```bash
curl http://localhost:4000/api/admin/me.enable_2fa \
-X POST \
-H "Accept: application/vnd.omisego.v1+json" \
-H "Authorization: OMGAdmin $(echo -n "user_id:auth_token" | base64 | tr -d '\n')" \
-H "Content-Type: application/json" \
-d '{
  "passcode": "103405"
}' \
-v -w "\n" | jq
```

If the `passcode` is correct, the response will be similar to:

```json
{
  "version": "1",
  "success": true,
  "data": {}
}
```

If everything was done correctly, the admin user account should now be secured with two-factor authentication.

Next, we will look into how can we log in with 2FA.

### Log in with 2FA

After the admin user has enabled two-factor authentication successfully, the user will need to do a 2-step login to fully obtain the authentication token which we normally use to access the authenticated APIs.

First, we need to obtain the pre-authentication token from the `/admin.login` endpoint.

1. Login with email and password

```bash
curl http://localhost:4000/api/admin/admin.login \
-X POST \
-H "Accept: application/vnd.omisego.v1+json" \
-H "Content-Type: application/json" \
-d '{
  "email": "user@example.com",
  "password": "p455w0RD"
}' \
-v -w "\n" | jq
```

The response would be look similar to:

```json
{
    "version": "1",
    "success": true,
    "data": {
        "user_id": "usr_01d9m837smphv4kx7xpaxm4dxp",
        "user": {},
        "role": null,
        "pre_authentication_token": "W9Yz6v5j3h9Z2q71NSDOmt8AR5cYw_m8KcIZHUVki_0",
        "object": "pre_authentication_token",
        "master_admin": null,
        "global_role": "super_admin",
        "account_id": null,
        "account": null
    }
}
```

Second, call the two-factor authentication endpoint `/admin.login_2fa` by using the `pre_authentication_token` which we take from the previous step to form the authorization header, also specify the passcode which was generated by the TOTP authenticator app in the body like below:

2. Login with passcode (or backup_code)

```bash
curl http://localhost:4000/api/admin/admin.login_2fa \
-X POST \
-H "Accept: application/vnd.omisego.v1+json" \
-H "Authorization: OMGAdmin $(echo -n "user_id:pre_auth_token" | base64 | tr -d '\n')" \
-H "Content-Type: application/json" \
-d '{
  "passcode": "103405"
}' \
-v -w "\n" | jq
```

The response will look similar to the previous login response, except the `pre_authentication_token`, which will be now a real `authentication_token`:

```json
{
    "version": "1",
    "success": true,
    "data": {
        "user_id": "usr_01d9m837smphv4kx7xpaxm4dxp",
        "user": {},
        "role": null,
        "authentication_token": "JAnlHGB3GNDt51TGZeFGoip55gRIdhnefALZHhhdSv8",
        "object": "authentication_token",
        "master_admin": null,
        "global_role": "super_admin",
        "account_id": null,
        "account": null
    }
}
```

Now, we can use the `user_id` and `authentication_token` from the response to form the valid authorization header, which can then be used to access the authenticated APIs.

### Disable 2FA

To disable the two-factor authentication, call the endpoint `/me.disable_2fa` as follows:

```bash
curl http://localhost:4000/api/admin/me.disable_2fa \
-X POST \
-H "Accept: application/vnd.omisego.v1+json" \
-H "Authorization: OMGAdmin $(echo -n "user_id:auth_token" | base64 | tr -d '\n')" \
-H "Content-Type: application/json" \
-d '{
  "passcode": "103405"
}' \
-v -w "\n" | jq
```

If the `passcode` is correct, the response will look like the following:

```json
{
  "version": "1",
  "success": true,
  "data": {}
}
```

### Note

1. The user's authentication tokens are deleted after two-factor authentication is enabled or disabled, so re-logins might be required.

2. `backup_code` can be used for login and/or disable two-factor authentication.

3. Each `backup_code` can be used only once.

4. `pre_authentication_token` is returned only when the user has two-factor authentication enabled, otherwise the `authentication_token` is returned right after the user logs in with username and password.
