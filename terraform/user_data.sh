#!/bin/bash
set -euo pipefail

exec > >(tee /var/log/user_data.log) 2>&1

echo "=== Starting setup at $(date) ==="

# Update system
dnf update -y

# Install PostgreSQL 16
dnf install -y postgresql16-server postgresql16 postgresql16-contrib
postgresql-setup --initdb

# Start and enable PostgreSQL
systemctl enable --now postgresql

# Configure PostgreSQL to listen on localhost and docker bridge
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = 'localhost,0.0.0.0'/" /var/lib/pgsql/data/postgresql.conf

# Set PostgreSQL password and create database
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${db_password}';"
sudo -u postgres psql -c "CREATE DATABASE auth_db;"
sudo -u postgres psql -d auth_db -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"

# Configure PostgreSQL authentication
cat > /var/lib/pgsql/data/pg_hba.conf << 'EOF'
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
host    all             all             172.16.0.0/12           md5
EOF

systemctl restart postgresql

# Install Git and Docker
dnf install -y git
dnf install -y docker
systemctl enable --now docker

# Clone the app
cd /opt
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=echo
if [ ! -d "express-auth-app" ]; then
  git clone https://github.com/reyn-nova/express-auth-app.git express-auth-app
  cd express-auth-app
  git checkout ${git_branch}
else
  cd express-auth-app
  git pull
  git checkout ${git_branch}
fi

# Build Docker image
docker build -t express-auth-app .

# Get public IP for CORS
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Create environment file for runtime config
cat > /opt/express-auth-app/.env << EOF
NODE_ENV=${node_env}
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=${db_password}
DB_DATABASE=auth_db
JWT_SECRET=${jwt_secret}
JWT_EXPIRES_IN=1d
COOKIE_NAME=access_token
COOKIE_SECURE=true
CORS_ORIGIN=http://$$PUBLIC_IP
EOF

# Run the container with host network
docker rm -f express-auth-app 2>/dev/null || true
docker run -d \
  --name express-auth-app \
  --restart unless-stopped \
  --network host \
  --env-file /opt/express-auth-app/.env \
  express-auth-app

# Redirect port 80 to 3000
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3000
iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-port 3000

echo "=== Setup completed at $(date) ==="
echo "App is running on port 80 via Docker"
echo "URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
