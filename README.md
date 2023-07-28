# Locationless-API-management

Organizations face the complex challenge of managing APIs deployed across diverse environments using a unfiied API managment platform while prioritizing security and compliance. Enter "Locationless API Management," a game-changing approach that combines the robust capabilities of 3scale API management and Skupper to enable seamless, secure, and flexible API deployment and auto discovery of APIs deployed across various footprints without exposing them to the internet.


This demo showcases how you can use 3scale and skupper together to automatically discover APIs in 3scale, regardless of where they are deployed. We deploy two APIs - one on an OpenShift cluster (different from the one where 3scale is installed) and the other on a RHEL VM. By combining the connectivity and discovery capabilities of Skupper and the 3scale, both APIs can be auto discovered in 3scale and without the need to make them publicly accesible over the internet.
