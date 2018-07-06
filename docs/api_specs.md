OmiseGO exposed API definitions
===============

OpenAPI definitions, allow devs to specify the operations and metadata of their APIs in machine-readable form. This enables them to automate various processes around the API lifecycle.

OmiseGO provides two APIs (eWallet adn Admin) and two definition which you can use to generate your client libraries.

### Build JSON OpenAPI definition

To build from source, you need the following installed and available in your `$PATH:`

* [Java 8](http://java.oracle.com)

* [Apache maven 3.3.3 or greater](http://maven.apache.org/)

The repository already contains OpenAPI binary. To generate the json definition from yaml run the following commands for each API.

**eWallet API:**

```sh
$ java -jar bin/openapi-generator-cli.jar generate -i apps/ewallet_api/priv/spec.yaml \
       -g openapi \
       -o apps/ewallet_api/priv/specification \
  && mv apps/ewallet_api/priv/specification/openapi.json apps/ewallet_api/priv/spec.json \
  && rm -rf apps/ewallet_api/priv/specification
```

**Admin API:**

```sh
$ java -jar bin/openapi-generator-cli.jar generate -i apps/admin_api/priv/spec.yaml \
       -g openapi \
       -o apps/admin_api/priv/specification \
  && mv apps/admin_api/priv/specification/openapi.json apps/admin_api/priv/spec.json \
  && rm -rf apps/admin_api/priv/specification
```
