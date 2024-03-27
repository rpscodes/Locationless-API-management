# Locationless-API-management

Organizations face the complex challenge of managing APIs deployed across diverse environments using a unfiied API managment platform while prioritizing security and compliance. Enter "Locationless API Management," a game-changing approach that combines the robust capabilities of 3scale API management and Skupper to enable seamless, secure, and flexible API deployment and auto discovery of APIs deployed across various footprints without exposing them to the internet.


This demo showcases how you can use 3scale and skupper together to automatically discover APIs in 3scale, regardless of where they are deployed. We deploy two APIs - one on an OpenShift cluster (different from the one where 3scale is installed) and the other on a RHEL VM. By combining the connectivity and discovery capabilities of Skupper and the 3scale, both APIs can be auto discovered in 3scale and without the need to make them publicly accessible over the internet.

## Prerequisites
1. Two OpenShift Clusters one for 3scale installation and the other for deploying your API
2. RHEL VM.
3. [OpenShift CLI (oc client)](https://docs.openshift.com/container-platform/4.15/cli_reference/openshift_cli/getting-started-cli.html)
4. [Ansible CLI](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) with [Ansible kubernetes.core module](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s_module.html)

##### Note: You can use any type of Kubernetes and VMs for this scenario. But this demo uses OpenShift and RHEL

## Installation
We'll be using two different OpenShift clusters. Let's refer to them as Public cluster and Private cluster respectively for the purpose of this demo

Login into both the clusters on separate terminals on your local machine and set the context
Public:
```
export KUBECONFIG=~/.kube/config-public
oc login --token=<token> --server=<serverURL> 
oc new-project public
oc config set-context --current --namespace public
```
Private:
```
export KUBECONFIG=~/.kube/config-private
oc login --token=<token> --server=<serverURL> 
oc new-project private
oc config set-context --current --namespace private
```

### Install Red Hat Service Interconnect on your local machine
```
curl https://skupper.io/install.sh | sh
```


### Public Cluster
- **Install 3scale**
    - Clone the playbook
    ```
    git clone https://github.com/rpscodes/3scale-install-playbooks.git
    ```
    - Navigate to the playbook folder
    ```
    cd 3scale-install-playbooks/ansible
    ```
    - Run the playbook
    ```
    ansible-playbook playbooks/install.yml -e"ACTION=install"
    ```
### Private Cluster
- **Deploy the Quarkus API(List of fruits)**
    - Clone the repository
    ```
    git clone https://github.com/rpscodes/rhoam-quarkus-openapi.git
    ```
    - Navigate to the folder
    ```
    cd rhoam-quarkus-openapi/
    ```
    - Deploy the API
    ```
    ./mvnw clean package -Dquarkus.kubernetes.deploy=true -Dquarkus.openshift.expose=true
    ```
### RHEL VM
- Deploy the simple Node.js api(list of books and their details)
```
podman run --name my-node-api -p 8080:8080 quay.io/vravula_redhat/node-api:test
```
- Make an API call to verify the deployment
```
curl http://localhost:8080/books
```

- Install Red Hat Service Interconnect/Skupper and set the necessary environment variables
```
curl https://skupper.io/install.sh | sh
systemctl --user enable podman.socket --now
export SKUPPER_PLATFORM=podman
skupper switch

```

## Make the APIs reachable to the Public OpenShift Cluster using Red Hat Service Interconnect

### Public Cluster
- Initialize the Service Interconnect router
```
skupper init --enable-console --enable-flow-collector --console-auth unsecured
```

- Create a secure token that for the private cluster to utilize to connect to the namespace on the public cluster. 
```
skupper token create secret_public_private.token
```

### Private Cluster
- Initialize the Service Interconnect router
```
skupper init
```

- Create the link using the token created in the public cluster in the previous section
```
skupper link create secret_public_private.token
```
- Expose the Quarkus API over the skupper network on to the public Openshift cluster
````
skupper expose service quarkus-openapi --address quarkus-openapi --port 8080 --protocol http
````
### Public Cluster

- Create a secure token for the RHEL VM to utilize to connect to the namespace on the public cluster
````
skupper token create secret_public_vm.token
````
- Display the token and copy it in a notepad
````
cat secret_public_vm.token
````

### RHEL VM
- Initialize the router
````
skupper init --ingress none
````
- Copy and paste the token created in public cluster in the file below
```
vim secret_public_vm.token
```

- Create the link using the token
```
skupper link create secret_public_vm.token --name public-to-vm
```

- Expose the API (podman container running on the RHEL machine) over the skupper network
```
skupper expose host host.containers.internal --address nodejs-api --port 8080 --protocol http
```
### Public Cluster
- Create a corresponding skupper virtual service for the Books API on Public cluster
```
skupper service create nodejs-api 8080 --protocol http
```

## Annotating the services for 3scale auto discovery

### Public Cluster
- Quarkus API
````
oc annotate svc/quarkus-openapi "discovery.3scale.net/description-path=/openapi?format=json"
oc annotate svc/quarkus-openapi discovery.3scale.net/port="8080"
oc annotate svc/quarkus-openapi discovery.3scale.net/scheme=http
oc label svc/quarkus-openapi discovery.3scale.net="true"

````

- Nodejs API
````
oc annotate svc/nodejs-api discovery.3scale.net/port="8080"
oc annotate svc/nodejs-api discovery.3scale.net/scheme=http
oc label svc/nodejs-api discovery.3scale.net="true"
````
- Give 3scale necessary permissions to discover these if needed
````
oc adm policy add-cluster-role-to-user view system:serviceaccount:3scale:amp
````

3scale should now be able to auto discover both these APIs. If you try to reach the APIs from the 3scale gateway using the appropriate authentication, you should able to see the proper response from the APIs


## High Availability
If you deploy another instance of the API on another cluster/VM and expose it on the service interconnect network with the same name when one instance, goes down the other will seamlessly take over. Let's test that scenario with the Nodejs API

## Private cluster 
- Deploy the Nodejs API in the private cluster
```
oc new-app quay.io/vravula_redhat/node-api:test
```

- Since we've already connected the public and private clusters earlier, we just need to expose the service with the same service address as the we did for the earlier deployment on the Node.js API on the network
```
skupper expose service node-api --address nodejs-api --port 8080 --protocol http
```

## RHEL VM
- Kill the container where the API is deployed
````
podman kill my-node-api && podman rm my-node-api
````

Call the Node.js APi through the 3scale gateway. You should see be able to see a 200 response with a json consisting of book details. This shows that though the API in the VM went down, Red Hat Service Interconnect automatically routed the traffic to the instance on the private cluster. 


 















