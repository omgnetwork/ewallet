# Users

# User types

User type | Determinator | Type-specific data
--------- | ------------ | ------------------
**User** | Any record in `user` table | N/A
**Master Admin** | `provider_user_id` == nil<br />`role` == "admin" on the top-level account | `email`, `password`
**Admin** | `provider_user_id` == nil | `email`, `password`
**End User** | `provider_user_id` != nil | `provider_user_id`

Note that user types above are not necessarily mutually exclusive. For example, a `Master Admin` is also an `Admin`. An `Admin` can be an `End User` too. Always pick the checker function that is most specific to your needs.

## Checker functions

Function | Master Admin | Admin | End User
-------- | ------------ | ----- | --------
`User.master_admin?/1` | `true` | `false` | `false`
`User.admin?/1` | `true` | `true` | `false`
`User.end_user?/1` | `false` | `false` | `true`

# User roles

Two default roles are predefined after seeding: `admin` and `viewer`.
