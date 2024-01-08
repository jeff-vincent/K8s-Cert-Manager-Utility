#!/bin/bash

kubectl create ns ingress-nginx

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx

# Retry loop for deploying test ingress
MAX_RETRIES=10
for ((i=1; i<=MAX_RETRIES; i++)); do
    kubectl apply -f test-ingress.yaml && break
    echo "Error: Failed to apply test ingress. Retrying ($i/$MAX_RETRIES)..."
    sleep 10
    if [ $i -eq $MAX_RETRIES ]; then
        echo "Error: Maximum retries reached. Exiting script."
        exit 1
    fi
done

# Retry loop for getting external IP
EXTERNAL_IP=""
while [ -z "$EXTERNAL_IP" ]; do
    EXTERNAL_IP=$(kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -z "$EXTERNAL_IP" ]; then
        echo "Waiting for external IP..."
        sleep 10 
    fi
done

echo "Add the following IP address to your DNS provider: $EXTERNAL_IP"
