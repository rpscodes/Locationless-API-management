#!/bin/bash

# Annotate quarkus-openapi service
oc annotate svc/quarkus-openapi "discovery.3scale.net/description-path=/openapi?format=json" >/dev/null 2>&1
oc annotate svc/quarkus-openapi discovery.3scale.net/port="8080" >/dev/null 2>&1
oc annotate svc/quarkus-openapi discovery.3scale.net/scheme=http >/dev/null 2>&1
oc label svc/quarkus-openapi discovery.3scale.net="true" >/dev/null 2>&1

# Annotate nodejs-api service
oc annotate svc/nodejs-api discovery.3scale.net/port="8080" >/dev/null 2>&1
oc annotate svc/nodejs-api discovery.3scale.net/scheme=http >/dev/null 2>&1
oc label svc/nodejs-api discovery.3scale.net="true" >/dev/null 2>&1

# Add cluster role to user
oc adm policy add-cluster-role-to-user view system:serviceaccount:3scale:amp >/dev/null 2>&1

echo "Service label complete"
