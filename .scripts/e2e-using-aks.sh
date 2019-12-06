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
kubectl apply -f config-service.yaml
kubectl apply -f registry-deployment.yaml
kubectl apply -f registry-service.yaml
kubectl apply -f gateway-deployment.yaml
kubectl apply -f gateway-service.yaml
kubectl apply -f account-service-deployment.yaml
kubectl apply -f account-service-service.yaml
kubectl apply -f auth-service-deployment.yaml
kubectl apply -f auth-service-service.yaml
kubectl apply -f statistics-service-deployment.yaml
kubectl apply -f statistics-service-service.yaml
kubectl apply -f notification-service-deployment.yaml
kubectl apply -f notification-service-service.yaml

bash-3.2$ kubectl get services
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)          AGE
account-service        ClusterIP      10.0.195.104   <none>          6000/TCP         4m13s
auth-service           ClusterIP      10.0.131.170   <none>          5000/TCP         3m35s
config                 LoadBalancer   10.0.49.222    51.143.107.33   8888:31212/TCP   6m28s
gateway                LoadBalancer   10.0.208.189   40.91.122.33    80:32131/TCP     5m
kubernetes             ClusterIP      10.0.0.1       <none>          443/TCP          48d
notification-service   ClusterIP      10.0.60.69     <none>          8000/TCP         3m2s
registry               LoadBalancer   10.0.122.108   52.143.74.122   8761:32475/TCP   5m31s
statistics-service     ClusterIP      10.0.232.183   <none>          7000/TCP         3m17s


# few additional commands

kubectl get pods
kubectl get services
kubectl get svc gateway
kubectl delete pod [pod-name]

http://.../actuator

# https://codefresh.io/kubernetes-tutorial/kubernetes-cheat-sheet/


# Azure Monitor - Kusto Query
let ContainerIdList = KubePodInventory
| where ContainerName contains  "/statistics-service"
| where ClusterId =~ '/subscriptions/343129b6-cc9a-49f8-8b05-fbebbc594bd1/resourceGroups/e2e-java-microservices-to-aks/providers/Microsoft.ContainerService/managedClusters/aks4piggymetrics'
| distinct ContainerID;
ContainerLog
| where ContainerID in (ContainerIdList)
| project LogEntrySource, LogEntry, TimeGenerated, Computer, Image, Name, ContainerID
| order by TimeGenerated desc
| render table


# Code Less Insights using Application Insights

# https://github.com/microsoft/Application-Insights-K8s-Codeless-Attach/blob/master/SETUP.md

# Install helm
# https://helm.sh/docs/intro/install/

brew install helm

# Install dos2unix

brew install dos2unix

# Download code-less insights software

# https://github.com/microsoft/Application-Insights-K8s-Codeless-Attach/releases

# Execute init.sh from the release in a linux terminal

source init.sh

# Edit values.yaml
# fill up AKS target namespace and Application Insights instrumentation key

# install code-less insights

helm install ./helm-version.tgz -f values.yaml

====

bash-3.2$ helm install ./helm-v0.7.tgz -f values.yaml --generate-name
NAME: helm-v0-1575305184
LAST DEPLOYED: Mon Dec  2 08:46:25 2019
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None