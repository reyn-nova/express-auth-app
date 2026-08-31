#!/bin/bash
set -euo pipefail

# Log output to /var/log/user_data.log
exec > >(tee /var/log/user_data.log) 2>&1

echo "=== Starting setup at $(date) ==="

# Update system
dnf update -y

# Install PostgreSQL 16
dnf install -y postgresql16-server postgresql16
postgresql-setup --initdb

# Start and enable PostgreSQL
systemctl enable --now postgresql

# Configure PostgreSQL to listen on localhost only (security)
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = 'localhost'/" /var/lib/pgsql/data/postgresql.conf

# Set PostgreSQL password and create database
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${db_password}';"
sudo -u postgres psql -c "CREATE DATABASE auth_db;"

# Configure PostgreSQL authentication (local password auth)
cat > /var/lib/pgsql/data/pg_hba.conf << 'EOF'
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
EOF

systemctl restart postgresql

# Install Git and Node.js 22
dnf install -y git
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs

# Configure git
git config --global init.defaultBranch main

# Verify installations
echo "Node version: $(node --version)"
echo "npm version: $(npm --version)"
echo "PostgreSQL version: $(psql --version)"

# Create app directory and user
useradd -r -s /bin/false appuser || true
mkdir -p /opt/express-auth-app
chown appuser:appuser /opt/express-auth-app

# Clone or copy the app (you'll need to upload your code or use git)
# For now, we'll create a placeholder - update with your actual repo
cd /opt/express-auth-app

# Create a setup script that clones and builds the app
cat > /opt/express-auth-app/setup.sh << 'SETUP_EOF'
#!/bin/bash
set -e

cd /opt/express-auth-app

# Clone repo (only if not already cloned)
if [ ! -d ".git" ]; then
  git clone ${git_repo} .
  git checkout ${git_branch}
fi

# Install dependencies
npm ci --production

# Build TypeScript
npm run build

# Run migrations
npm run migration:run

echo "App setup completed!"
SETUP_EOF

chmod +x /opt/express-auth-app/setup.sh

# Create environment file
cat > /opt/express-auth-app/.env << EOF
NODE_ENV=${node_env}
PORT=80
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=${db_password}
DB_DATABASE=auth_db
JWT_SECRET=${jwt_secret}
JWT_EXPIRES_IN=1d
COOKIE_NAME=access_token
COOKIE_SECURE=true
CORS_ORIGIN=${cors_origin}
EOF

chown appuser:appuser /opt/express-auth-app/.env
chmod 600 /opt/express-auth-app/.env

# Install pm2 globally
npm install -g pm2

# Create systemd service for the app
cat > /etc/systemd/system/express-auth.service << 'SERVICE_EOF'
[Unit]
Description=Express Auth App
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=appuser
Group=appuser
WorkingDirectory=/opt/express-auth-app
ExecStart=/usr/bin/node dist/server.js
Restart=on-failure
RestartSec=5
Environment=NODE_ENV=production
EnvironmentFile=/opt/express-auth-app/.env

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# Enable the service (but don't start yet - app code not deployed)
systemctl daemon-reload
systemctl enable express-auth

# Run setup on first boot (clone, install, build, migrate)
sudo -u appuser bash /opt/express-auth-app/setup.sh

# Start the app
systemctl start express-auth

echo "=== Setup completed at $(date) ==="
echo "App is running on port 80"
echo "URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
