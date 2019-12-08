#!/usr/bin/env bash

mkdir -p deploy
envsubst < 0-secrets.yaml > deploy/0-secrets.yaml
envsubst < 1-config.yaml > deploy/1-config.yaml
envsubst < 2-registry.yaml > deploy/2-registry.yaml
envsubst < 3-gateway.yaml  > deploy/3-gateway.yaml
envsubst < 4-auth-service.yaml > deploy/4-auth-service.yaml
envsubst < 5-account-service.yaml > deploy/5-account-service.yaml
envsubst < 6-statistics-service.yaml > deploy/6-statistics-service.yaml
envsubst < 7-notification-service.yaml > deploy/7-notification-service.yaml