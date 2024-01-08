#!/bin/bash

# Function to check if the certificate is ready
is_certificate_ready() {
    kubectl get certificate letsencrypt-rf28h -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep True
}

# Function to make the curl request
make_curl_request() {
    curl "https://$dns_name"
}

# Prompt user for DNS name
read -p "Enter the DNS name for the certificate: " dns_name

# Update Ingress YAML template with the user-provided DNS name
cat <<EOF > tls-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - $dns_name
    secretName: letsencrypt-rf28h
  rules:
    - host: $dns_name
      http:
        paths:
          - pathType: Prefix
            path: "/"
            backend:
              service:
                name: app
                port:
                  number: 8080
EOF

# Apply Ingress YAML
kubectl apply -f tls-ingress.yaml

# Retry loop for certificate readiness
while true; do
    # Check if the certificate is ready
    if is_certificate_ready; then
        echo "Certificate is ready."
        break
    else
        echo "Certificate not ready. Retrying..."
    fi

    sleep 5
done

# Retry loop for the curl request
max_retries_curl=5
retry_count_curl=0

while true; do
    # Increment the retry count for curl request
    ((retry_count_curl++))

    # Make the curl request
    make_curl_request

    # Check the exit status of the last curl command
    if [ $? -eq 0 ]; then
        echo "Curl request successful."
        break
    else
        echo "Error making curl request. Retrying..."
    fi

    # Check if max retries for curl request reached
    if [ $retry_count_curl -eq $max_retries_curl ]; then
        echo "Max retries for curl request reached. Exiting..."
        exit 1
    fi

    # Wait for a short duration before retrying
    sleep 5
done
