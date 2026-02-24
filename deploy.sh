#!/bin/bash
APP=""
VERSION=""
ENV=""

for arg in "$@"; do
  case $arg in
    --app=*) APP="${arg#*=}";;
    --version=*) VERSION="${arg#*=}";;
    --env=*) ENV="${arg#*=}";;
  esac
done

if [ -z "$APP" ] || [ -z "$VERSION" ] || [ -z "$ENV" ]; then
  echo "Usage: $0 --app=NAME --version=X.X --env=ENV"
  exit 1
fi

for tool in git docker nginx curl; do
  if ! command -v $tool &> /dev/null; then
    echo "Error: $tool not found"
    exit 1
  fi
done

REPO_URL="https://github.com/vardgesss-dev/scx_webdev_pr2.git"
DEPLOY_DIR="/tmp/$APP"
BACKUP_DIR="/tmp/backups/$APP"

mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [ -d "$DEPLOY_DIR" ]; then
  cp -r "$DEPLOY_DIR" "$BACKUP_DIR/backup_$TIMESTAMP"
  echo "Backup saved: $BACKUP_DIR/backup_$TIMESTAMP"
  rm -rf "$DEPLOY_DIR"
fi

git clone "$REPO_URL" "$DEPLOY_DIR" || exit 1
cd "$DEPLOY_DIR"

docker build -t "$APP:$VERSION" . || exit 1
docker stop "$APP" 2>/dev/null || true
docker rm "$APP" 2>/dev/null || true
docker run -d --name "$APP" -p 80:80 "$APP:$VERSION" || exit 1

sleep 5
if curl -s -o /dev/null -w "%{http_code}" http://localhost/ | grep -q 200; then
  echo "Deploy successful"
  exit 0
else
  echo "Health check failed, rolling back..."
  docker stop "$APP" && docker rm "$APP"
  if [ -d "$BACKUP_DIR/backup_$TIMESTAMP" ]; then
    rm -rf "$DEPLOY_DIR"
    cp -r "$BACKUP_DIR/backup_$TIMESTAMP" "$DEPLOY_DIR"
    docker run -d --name "$APP" -p 80:80 "$APP:$VERSION"
  fi
  exit 1
fi
