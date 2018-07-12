OmiseGO exposed API definitions
===============

OpenAPI definitions, allow devs to specify the operations and metadata of their APIs in machine-readable form. This enables them to automate various processes around the API lifecycle.

OmiseGO provides two APIs (eWallet API and Admin API) and two definitions which you can use to generate your client libraries.

The YAML definitions are the primary format for editing and therefore are the only format included in the repository. Other API definitions generated should be based on the YAML definitions.

### Prerequisites

To build the JSON definitions, you need the following installed and available in your `$PATH:`

* [Java 8](http://java.oracle.com)
* [inotify-tools](https://github.com/rvoicilas/inotify-tools/wiki) (required for Linux-based OS's)

When running an active ewallet server through `mix omg.server`, the JSON definitions are generated automatically every time a change to the YAML definition is detected.

### Building the JSON OpenAPI definition manually

To generate the json definition manually without running the server, use the following commands:

**eWallet API:**

```sh
$ java -jar bin/openapi-generator-cli.jar generate -i apps/ewallet_api/priv/spec.yaml \
       -g openapi \
       -o apps/ewallet_api/priv/spec_temp \
  && mv apps/ewallet_api/priv/spec_temp/openapi.json apps/ewallet_api/priv/spec.json \
  && rm -rf apps/ewallet_api/priv/spec_temp
```

**Admin API:**

```sh
$ java -jar bin/openapi-generator-cli.jar generate -i apps/admin_api/priv/spec.yaml \
       -g openapi \
       -o apps/admin_api/priv/spec_temp \
  && mv apps/admin_api/priv/spec_temp/openapi.json apps/admin_api/priv/spec.json \
  && rm -rf apps/admin_api/priv/spec_temp
```
