# Kubera

API for external clients to interact with Caishen.

## App Responsibilities & Dependencies

* **kubera**: Kubera's umbrella app
    * **kubera_db**: Kubera's persistent data layer
    * **kubera_api**: Kubera's endpoints for clients to connect in (requires kubera_db)
