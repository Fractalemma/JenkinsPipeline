#!/bin/bash
set -euxo pipefail

yum update -y
amazon-linux-extras install -y nginx1
systemctl enable nginx
systemctl start nginx

# Tools
yum install -y unzip jq
# AL2 usually has SSM agent already. Ensure it's running:
systemctl enable amazon-ssm-agent || true
systemctl start amazon-ssm-agent || true

# AWS CLI v2 (if missing)
if ! command -v aws >/dev/null 2>&1; then
  curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  ./aws/install
fi

# Atomic deploy structure
mkdir -p /var/www/releases /var/www/shared/log /var/www/tmp
# symlink target
if [[ ! -e /var/www/current ]]; then
  ln -s /var/www/releases/initial /var/www/current || true
fi
chown -R nginx:nginx /var/www

# Nginx site
cat >/etc/nginx/conf.d/myapp.conf <<'NGINX'
server {
  listen 80;
  server_name _;

  root /var/www/current;
  index index.html;

  location / {
    try_files $uri $uri/ /index.html;
  }

  location ~* \.(?:js|css|svg|png|jpg|jpeg|gif|ico|woff2?)$ {
    expires 7d;
    add_header Cache-Control "public, max-age=604800, immutable";
  }
}
NGINX
nginx -t && systemctl reload nginx

# Deploy helper script (called via SSM)
cat >/opt/deploy/pull_and_switch.sh <<'DEPLOY'
#!/usr/bin/env bash
set -euo pipefail
# Args:
#   1 = S3 bucket
#   2 = S3 key (object key of the zip)
# Example:
#   pull_and_switch.sh my-bucket myapp/releases/2025-10-27T18-31-00_abc123.zip

BUCKET="$1"
KEY="$2"

if [[ -z "${BUCKET}" || -z "${KEY}" ]]; then
  echo "Usage: pull_and_switch.sh <bucket> <key>" >&2
  exit 1
fi

REL="release_$(date +%Y%m%d_%H%M%S)_$(echo "${KEY}" | rev | cut -d'/' -f1 | rev | sed 's/\.zip$//')"
WORKDIR="/var/www/releases/${REL}"
TMP_ZIP="/var/www/tmp/${REL}.zip"

mkdir -p "${WORKDIR}"
aws s3 cp "s3://${BUCKET}/${KEY}" "${TMP_ZIP}"

unzip -q -o "${TMP_ZIP}" -d "${WORKDIR}"
rm -f "${TMP_ZIP}"

# Atomic switch
ln -sfn "${WORKDIR}" /var/www/current
chown -h nginx:nginx /var/www/current
chown -R nginx:nginx "${WORKDIR}"

# Optional: verify index exists
test -f "/var/www/current/index.html" || { echo "index.html missing"; exit 2; }

echo "Deployed ${REL} from s3://${BUCKET}/${KEY}"
DEPLOY
chmod +x /opt/deploy/pull_and_switch.sh
