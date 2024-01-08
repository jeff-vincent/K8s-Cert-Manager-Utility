#!/bin/bash

# Define the number of retries
max_retries=10
retry_count=0

# Function to apply issuer.yaml
apply_issuer() {
    kubectl apply -f issuer.yaml -n cert-manager
}

# Prompt user for email address
read -p "Enter your email address for ACME registration: " user_email

# Create namespace cert-manager if it doesn't exist
kubectl create ns cert-manager 2>/dev/null

# Apply cert-manager.yaml
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.7.1/cert-manager.yaml

# Update issuer.yaml with the user-provided email
cat <<EOF > issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: cert-manager
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $user_email
    privateKeySecretRef:
      name: letsencrypt
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Retry loop
while true; do
    # Increment the retry count
    ((retry_count++))

    # Call the function to apply issuer.yaml
    apply_issuer

    # Check the exit status of the last command
    if [ $? -eq 0 ]; then
        echo "Issuer.yaml applied successfully."
        break
    else
        echo "Error applying issuer.yaml. Retrying..."
    fi

    # Check if max retries reached
    if [ $retry_count -eq $max_retries ]; then
        echo "Max retries reached. Exiting..."
        exit 1
    fi

    # Wait for a short duration before retrying
    sleep 5
done
