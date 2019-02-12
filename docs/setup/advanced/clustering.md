# Clustering

**Note: This is experimental and is subjected to change.**

Some feature such as WebSockets require that Erlang nodes are connected. We support automatic clustering via DNS in `prod` environment using [Peerage](https://github.com/mrluc/peerage). To use automatic clustering, you must run the application in the following manner (in additional to standard configuration):

```
$ env MIX_ENV=prod NODE_DNS=ewallet.default.svc.cluster.local \
  elixir \
    --erl '-kernel inet_dist_listen_min 6900' \
    --erl '-kernel inet_dist_listen_max 6909' \
    --name ewallet@127.0.0.1 \
    --cookie secure_random_string \
    -S mix omg.server
```

The following environment variables are being used:

-   `MIX_ENV=prod` -- automatic clustering is only configured for production
-   `NODE_DNS=ewallet.default.svc.cluster.local` -- dns name to discover nodes (you have to change this)

The following options are being used:

-   `--erl '-kernel inet_dist_listen_min 6900'` -- min port for erlang to connect to nodes
-   `--erl '-kernel inet_dist_listen_max 6909'` -- max port for erlang to connect to nodes
-   `--name ewallet@127.0.0.1` -- name of the node, must be `ewallet@NODE_HOST` (hostname or ip)
-   `--cookie secure_random_string` -- secure and random string used for node authentication

Additionally, you will have to make sure that port `4369` and ports in the `inet_dist_listen_min` and `inet_dist_listen_max` range are accessible via firewall in order to allow nodes to communicate with each other.

## Docker/Kubernetes

The official Docker image has automatic clustering support built-in. You will need to set the following environment variables:

-   `NODE_DNS` -- dns name to discover nodes (e.g. [Kubernetes service DNS](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/))
-   `NODE_HOST` -- host name or ip address of the current container (e.g. Kubernetes Pod IP)

In Kubernetes, this can be done by adding the following to `spec.template.spec.containers[*].env[*]` (assuming eWallet service is created as "ewallet"):

```diff
 apiVersion: extensions/v1beta1
 kind: Deployment
 metadata:
   name: ewallet
   labels:
     app: ewallet
 spec:
   replicas: 3
   template:
     spec:
       containers:
         - name: ewallet
           image: omisego/ewallet:stable
           env:
             # ...snip...
+            - name: POD_NAMESPACE
+              valueFrom:
+                fieldRef:
+                  fieldPath: metadata.namespace
+            - name: NODE_HOST
+              valueFrom:
+                fieldRef:
+                  fieldPath: status.podIP
+            - name: NODE_DNS
+              value: ewallet.$(POD_NAMESPACE).svc.cluster.local
```

It is also important to set `spec.clusterIP` in service to `None` otherwise Kubernetes DNS will return a load-balanced cluster IP and automatic clustering will not work:

```diff
 kind: Service
 apiVersion: v1
 metadata:
   name: ewallet
   namespace: staging
 spec:
   type: ClusterIP
+  clusterIP: None
   selector:
     app: ewallet
   ports:
     # ...snip...
```

The official Docker image set `inet_dist_listen_min` to 6900 and `inet_dist_listen_max` to 6909 and expose port range 6900 to 6909 by default in addition to port 4369 and application port. Please make sure these ports are accessible from within Docker network or Kubernetes cluster.
