#!/bin/bash
set -euo pipefail

# deploy.sh - Deploy the app to EC2 instances
# Usage: ./deploy.sh <staging|production|both>

ENVIRONMENT=${1:-both}
KEY_FILE=${KEY_FILE:-~/.ssh/your-key.pem}

# Get instance IPs from Terraform output
cd "$(dirname "$0")"
STAGING_IP=$(terraform output -raw staging_public_ip)
PRODUCTION_IP=$(terraform output -raw production_public_ip)

deploy_to_instance() {
  local ip=$1
  local env=$2

  echo "=== Deploying to $env ($ip) ==="

  # Sync the app files (excluding node_modules, .git, terraform)
  rsync -avz --progress \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='terraform' \
    --exclude='docker-compose*.yml' \
    --exclude='Dockerfile*' \
    --exclude='.dockerignore' \
    -e "ssh -i $KEY_FILE" \
    ../ "$HOME/express-auth-deploy/"

  # Copy to instance
  scp -i "$KEY_FILE" -r "$HOME/express-auth-deploy/" ec2-user@"$ip":/tmp/express-auth-app/

  # Run setup on instance
  ssh -i "$KEY_FILE" ec2-user@"$ip" << 'REMOTE_EOF'
    sudo cp -r /tmp/express-auth-app/* /opt/express-auth-app/
    sudo chown -R appuser:appuser /opt/express-auth-app
    cd /opt/express-auth-app
    sudo -u appuser bash setup.sh
    sudo systemctl restart express-auth
    echo "=== Deployment completed ==="
    sudo systemctl status express-auth --no-pager
REMOTE_EOF

  echo "=== $env deployed successfully ==="
  echo "URL: http://$ip"
}

case $ENVIRONMENT in
  staging)
    deploy_to_instance "$STAGING_IP" "staging"
    ;;
  production)
    deploy_to_instance "$PRODUCTION_IP" "production"
    ;;
  both)
    deploy_to_instance "$STAGING_IP" "staging"
    deploy_to_instance "$PRODUCTION_IP" "production"
    ;;
  *)
    echo "Usage: $0 <staging|production|both>"
    exit 1
    ;;
esac
