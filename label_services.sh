#!/bin/bash

# Annotate quarkus-openapi service
oc annotate svc/quarkus-openapi "discovery.3scale.net/description-path=/openapi?format=json" >/dev/null
oc annotate svc/quarkus-openapi discovery.3scale.net/port="8080" >/dev/null
oc annotate svc/quarkus-openapi discovery.3scale.net/scheme=http >/dev/null
oc label svc/quarkus-openapi discovery.3scale.net="true" >/dev/null

# Annotate nodejs-api service
oc annotate svc/nodejs-api discovery.3scale.net/port="8080" >/dev/null
oc annotate svc/nodejs-api discovery.3scale.net/scheme=http >/dev/null
oc label svc/nodejs-api discovery.3scale.net="true" >/dev/null

# Add cluster role to user
oc adm policy add-cluster-role-to-user view system:serviceaccount:3scale:amp >/dev/null

echo "Service label complete"
