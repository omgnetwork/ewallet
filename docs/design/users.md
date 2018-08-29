# Users

# User types

User type | Determinator | Type-specific data
--------- | ------------ | ------------------
**User** | Any record in `user` table | -
**Master Admin** | Has `role` == "admin" on the top-level account | `email`, `password`
**Admin** | Has one or more `role` attached | `email`, `password`

Note that user types above are not mutually exclusive. For example, a `Master Admin` is also an `Admin`. An `Admin` is also a `User` too. Always pick the checker function that is most specific to your needs.

Also, the actual permissions that each `Admin` has are determined by the role-permission mapping, not the user type. For example, it may be possible for an `Admin` user to login to the admin panel but has no permissions to see any data.

## Checker functions

Function | Master Admin | Admin | User
-------- | ------------ | ----- | --------
`User.master_admin?/1` | `true` | `false` | `false`
`User.admin?/1` | `true` | `true` | `false`

Since all users  including admins can be end users, there is no checker function to check for an end user.

# User roles

Two default roles are predefined after seeding: `admin` and `viewer`.
