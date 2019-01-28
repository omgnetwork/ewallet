# Upgrading the eWallet Server

## Before you begin

1. **Backup the existing the database:** Always keep a working database backup so that you can restore the system
to the previous state when needed.
2. **Read the version-specific upgrade notes:** You may need to perform some tasks before or after the upgrade.
    - [Upgrading to `v1.1.0`](v1.1.0.md)
    - [Upgrading to `v1.0.0`](v1.0.0.md)

## Upgrade (docker-compose)

1. Navigate to your directory that contains the OmiseGO eWallet Server's docker-compose.yml:

    ```shell
    cd /path/to/your/ewallet/docker-compose/dir
    ```

2. Stop the eWallet server:

    ```shell
    docker-compose stop
    ```

3. Download the latest version of the [docker-compose.yml](https://raw.githubusercontent.com/omisego/ewallet/master/docker-compose.yml):

    ```shell
    curl -o -sSL https://raw.githubusercontent.com/omisego/ewallet/master/docker-compose.yml
    ```

3. Initialize the database and start the server:

    ```shell
    docker-compose run --rm ewallet initdb
    docker-compose up -d
    ```

## Upgrade (bare-metal setup)

This upgrade instructions assume that you installed the eWallet Server using our [bare-metal setup](../bare_metal.md).

1. Stop the eWallet server by simply pressing `Ctrl + C` twice.

2. Make sure you are in the eWallet Server's directory:

    ```shell
    cd /path/to/your/ewallet/server
    ```

2. Download the preferred version via `git checkout`:

    ```shell
    git checkout <version_tag>
    ```

    _Make sure that `<version_tag>` above is changed to your preferred [release](https://github.com/omisego/ewallet/releases)._

3. Fetch any new and updated dependencies:

    ```shell
    mix deps.get && (cd apps/admin_panel/assets/ && yarn install)
    ```

4. Migrate the databases and test the new codebase:

    ```shell
    mix ecto.migrate
    mix test
    ```

5. Start the server:

    ```shell
    mix omg.server
    ```
