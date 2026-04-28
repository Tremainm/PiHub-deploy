# PiHub Deploy

Production deployment repository for **PiHub** — a Raspberry Pi–based smart home hub that integrates Matter/Thread devices with a web dashboard.

Source code: [github.com/Tremainm/PiHub-FYP2025](https://github.com/Tremainm/PiHub-FYP2025)

---

## What this repo does

This repo contains everything needed to run PiHub on a Raspberry Pi. It pulls pre-built Docker images from GHCR and orchestrates them with Docker Compose. No source code or build steps are required on the device.

### Services

| Service | Image | Description |
|---|---|---|
| `db` | `postgres:17-alpine` | PostgreSQL database |
| `backend` | `ghcr.io/tremainm/pihub-backend:latest` | FastAPI backend (port 8000) |
| `frontend` | `ghcr.io/tremainm/pihub-frontend:latest` | React frontend (port 80) |
| `matter-server` | `ghcr.io/home-assistant-libs/python-matter-server:stable` | Matter/Thread device controller (port 5580) |

The `db`, `backend`, and `frontend` containers share a private `pihub-net` bridge network. `matter-server` runs in host network mode so it can reach Bluetooth and mDNS on the local network.

---

## Prerequisites

- Docker and Docker Compose installed on the Raspberry Pi
- A `.env` file in this directory (see below)
- `netcat` (`nc`) available on the host for the startup health checks

### `.env` file

The `.env` file is not committed to this repo. It must be created manually on the device. At minimum it should contain the Postgres credentials that match what the backend expects, for example:

```
POSTGRES_USER=pihub
POSTGRES_PASSWORD=yourpassword
POSTGRES_DB=pihub
```

---

## Usage

All operations go through `pihub.sh`.

```bash
# Start matter-server and the app stack
./pihub.sh

# Pull latest images from GHCR, then start
./pihub.sh --pull

# Start and stream logs (Ctrl+C to detach)
./pihub.sh --logs

# Stop the app stack (backend, frontend, db)
./pihub.sh --app-down

# Stop matter-server only
./pihub.sh --matter-down

# Stop everything
./pihub.sh --down-all

# Show help
./pihub.sh --options
```

The script waits for `matter-server` to be reachable on port 5580 before starting the app stack, and waits for the frontend to be reachable on port 80 before printing the local URL.

Startup output is logged to `/home/pihub/pihub-startup.log`.

---

## Updating

To deploy a new version of the backend or frontend:

```bash
./pihub.sh --pull
```

This pulls the latest images from GHCR and restarts the stack.
