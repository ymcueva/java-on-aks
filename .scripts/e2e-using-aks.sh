#!/usr/bin/env bash

# pre-requisite Java 8 | Maven | git | Docker

az acr create --name ${CONTAINER_REGISTRY} \
    --resource-group ${RESOURCE_GROUP} \
    --sku basic --location ${REGION}

az aks create --name ${AKS_CLUSTER} \
    --resource-group ${RESOURCE_GROUP} \
    --location ${REGION} \
    --attach-acr ${CONTAINER_REGISTRY} \
    --node-vm-size Standard_DS3_v2 \
    --node-count 5

az aks get-credentials --name ${AKS_CLUSTER} \
    --resource-group ${RESOURCE_GROUP}

az aks browse --name ${AKS_CLUSTER} \
    --resource-group ${RESOURCE_GROUP}

# https://github.com/Azure/acr-docker-credential-helper

curl -L https://aka.ms/acr/installaad/bash | /bin/bash

az acr login -n ${CONTAINER_REGISTRY}

cd config
mvn compile jib:build -Djib.container.environment=CONFIG_SERVICE_PASSWORD=${CONFIG_SERVICE_PASSWORD}

# docker rmi --force acr4piggymetrics.azurecr.io/config

cd registry
mvn compile jib:build

cd account-service
mvn compile jib:build -Djib.container.environment=ACCOUNT_SERVICE_PASSWORD=${ACCOUNT_SERVICE_PASSWORD}

cd auth-service
mvn compile jib:build

cd gateway
mvn compile jib:build

cd statistics-service
mvn compile jib:build -Djib.container.environment=STATISTICS_SERVICE_PASSWORD=${STATISTICS_SERVICE_PASSWORD}

cd notification-service
mvn compile jib:build -Djib.container.environment=NOTIFICATION_SERVICE_PASSWORD=${NOTIFICATION_SERVICE_PASSWORD}

# Start an instance of Spring Cloud Config

docker run -p 127.0.0.1:8888:8888 ${CONTAINER_REGISTRY}.azurecr.io/config

# install kubectl
# https://kubernetes.io/docs/tasks/tools/install-kubectl/

# install kompose
# https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/

kompose convert

kubectl apply -f config-deployment.yaml
kubectl apply -f registry-deployment.yaml
kubectl apply -f registry-service.yaml
kubectl apply -f gateway-deployment.yaml
kubectl apply -f gateway-service.yaml
kubectl apply -f account-service-deployment.yaml
kubectl apply -f auth-service-deployment.yaml
kubectl apply -f statistics-service-deployment.yaml
kubectl apply -f notification-service-deployment.yaml

kubectl expose deployment gateway --type=LoadBalancer --name=gateway

