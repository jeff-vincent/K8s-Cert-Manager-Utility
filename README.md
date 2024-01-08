# K8s-Cert-Manager-Utility
A collection of scripts to deploy and configure cert-manager in a K8s cluster.

## Prerequisites
- A kubernetes cluster with `kubectl` configured.
- A domain name registered with a DNS provider.

### Nginx
1. Run `./deploy_ingress.sh`
2. Add External IP to DNS provider as an "A Record" with the host "@". 
3. Run `./deploy_cert_manager.sh`
4. Run `./deploy_tls_ingress.sh`
