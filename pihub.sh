#!/bin/bash
set -e

cd /home/pihub/Desktop/PiHub-deploy
exec > /home/pihub/pihub-startup.log 2>&1
echo "start.sh began at $(date)"

if [ "$1" == "--options" ]; then
    echo "Usage: ./start.sh [flag]"
    echo ""
    echo "Startup:"
    echo "  (no flag)       Start matter-server and app stack"
    echo "  --pull          Pull latest images from GHCR then start"
    echo "  --logs          Start then attach to logs (Ctrl+C to detach)"
    echo ""
    echo "Shutdown:"
    echo "  --app-down      Stop the app stack (backend, frontend, db)"
    echo "  --matter-down   Stop the matter-server only"
    echo "  --down-all      Stop everything"
    echo ""
    echo "Other:"
    echo "  --options       Show this help message"
    exit 0
fi

VALID_FLAGS="--pull --logs --app-down --matter-down --down-all"
if [ -n "$1" ] && [[ ! " $VALID_FLAGS " =~ " $1 " ]]; then
    echo "Unknown flag: $1"
    echo "Run ./start.sh --options to see available flags."
    exit 1
fi

if [ "$1" == "--app-down" ]; then
    echo "Shutting down app stack..."
    docker compose down
    exit 0
fi

if [ "$1" == "--matter-down" ]; then
    echo "Shutting down matter-server..."
    docker compose -f docker-compose.matter.yml down
    exit 0
fi

if [ "$1" == "--down-all" ]; then
    echo "Shutting down app stack & matter-server..."
    docker compose down
    docker compose -f docker-compose.matter.yml down
    exit 0
fi

# Pass --pull to pull latest images from GHCR before starting
if [ "$1" == "--pull" ]; then
    echo "Pulling latest images..."
    docker compose pull
fi

echo "Starting matter-server..."
docker compose -f docker-compose.matter.yml up -d

echo "Waiting for matter-server to be ready..."
until nc -z localhost 5580 2>/dev/null; do
    echo "  matter-server not ready yet, retrying in 2s..."
    sleep 2
done

echo "matter-server is ready."
echo "Starting app stack..."
docker compose up -d

echo "Waiting for frontend to be ready..."
until nc -z localhost 80 2>/dev/null; do
    echo "  frontend not ready yet, retrying in 2s..."
    sleep 2
done
echo "Frontend is ready."

echo ""
echo "PiHub is up at http://$(hostname -I | awk '{print $1}')"

if [ "$1" == "--logs" ]; then
    echo ""
    echo "Attaching to logs (Ctrl+C to detach)..."
    docker compose logs -f
fi