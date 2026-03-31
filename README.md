# nobelproducts — Web Deployment

Production deployment for **6 screen-printing / garment websites** hosted on a single DigitalOcean droplet.
Each website is its own Next.js app running in a Docker container, fronted by a shared nginx reverse proxy with HTTPS (Let's Encrypt).

---

## Websites

| Short name | Domain | Source project | Container | Port |
|---|---|---|---|---|
| dragon | dragonscreenservice.com | `dragon-print-studio` | `dragon-screen-web` | 3011 |
| fenix | fenixscreen.com | `bangkok-screen-masters` | `fenix-screen-web` | 3010 |
| gustex | gustexscreen.com | `gustex-print-studio` | `gustex-screen-web` | 3013 |
| hotprint | hotprintscreen.com | `hotprint-screen-studio` | `hotprint-screen-web` | 3014 |
| turbo | turboscreenprint.com | `dtf-color-studio` | `turbo-screen-web` | 3012 |
| flash | flashscreendtf.com | `easy-site-builder` | `flash-screen-web` | 3015 |

> Some websites may be commented out in `docker-compose.yml` and `nginx.conf` while they are not yet active.

---

## Repository layout

```
web/
├── Makefile                                  # Build & save Docker images (run from monorepo root)
└── deployments/
    └── digitalocean/
        └── server1/
            ├── docker-compose.yml            # Runs all containers on the server
            ├── deploy.sh                     # Load .tar images + docker compose up
            ├── sync-prod.sh                  # rsync files to the server from local machine
            ├── init-certs.sh                 # ONE-TIME: install certbot + obtain all certs
            ├── renew-certs.sh                # Scheduled: renew certs every 60 days
            └── environments/
                ├── nginx/
                │   └── nginx.conf            # Reverse proxy config (HTTP→HTTPS + SSL)
                ├── dragon-screen/
                │   └── .env.prod
                ├── fenix-screen/
                │   └── .env.prod
                ├── gustex-screen/
                │   └── .env.prod
                ├── hotprint-screen/
                │   └── .env.prod
                ├── turbo-screen/
                │   └── .env.prod
                └── flash-screen/
                    └── .env.prod
```

---

## Architecture

```
Internet
   │
   ▼  :80 / :443
┌──────────────────────────────────────┐
│  nginx (Docker)                      │
│  • HTTP → HTTPS redirect (301)       │
│  • SSL termination (Let's Encrypt)   │
│  • Reverse proxy per domain          │
└──┬───────┬───────┬───────┬───────┬───┘
   │       │       │       │       │
   ▼       ▼       ▼       ▼       ▼
:3011   :3010   :3013   :3014   :3012   :3015
dragon  fenix  gustex  hotprint  turbo  flash
 web     web    web     web      web    web
```

All containers share `local-network` (Docker bridge). Nginx reaches each app by its container name (e.g. `dragon-screen-web:3011`).
SSL certificates are stored on the **host** at `/etc/letsencrypt` and bind-mounted read-only into the nginx container.

---

## Full deployment flow

### Prerequisites (local machine)

- Docker Desktop installed and running
- `make` available
- SSH access to the DigitalOcean server (`~/.ssh/id_rsa_fenix_screen`)
- All per-project `.env.prod` files filled in under `environments/<name>/.env.prod`

---

### Step 1 — Build Docker images (local machine)

Run from the **monorepo root** (`nobelproducts/`):

```bash
# Build all 6 images at once
make build-all

# Or build a single image
make build-dragon
make build-fenix
make build-gustex
make build-hotprint
make build-turbo
make build-flash
```

Each command delegates to the sub-project's own `docker-build` Make target.

---

### Step 2 — Save images to .tar files (local machine)

```bash
# Save all images to web/deployments/digitalocean/server1/images/
make save-all

# Or save individually
make save-dragon     # → images/dragon-screen-web.tar
make save-fenix      # → images/fenix-screen-web.tar
make save-gustex     # → images/gustex-screen-web.tar
make save-hotprint   # → images/hotprint-screen-web.tar
make save-turbo      # → images/turbo-screen-web.tar
make save-flash      # → images/flash-screen-web.tar
```

Or build and save in one command:

```bash
make build-and-save
```

---

### Step 3 — Sync files to server (local machine)

Edit `sync-prod.sh` to uncomment the items you want to sync, then run it from `server1/`:

```bash
cd web/deployments/digitalocean/server1
./sync-prod.sh
```

The script uses `rsync` over SSH. Common items to sync:

| Item | When to sync |
|---|---|
| `./environments` | Whenever `.env.prod` or `nginx.conf` changes |
| `./images` | After every build (large, takes time) |
| `./docker-compose.yml` | When adding/removing services |
| `./init-certs.sh` | First deploy only |
| `./renew-certs.sh` | When the renewal script changes |

---

### Step 4 — First-time SSL certificate setup (server — run once)

> Only needed on first deploy or on a fresh server. Skip if certs already exist under `/etc/letsencrypt/live/`.

```bash
# SSH into the server
ssh -i ~/.ssh/id_rsa_fenix_screen root@146.190.200.50

cd /root/nobelproducts

# Make sure no containers are running (port 80 must be free)
docker compose down

# Run the init script with your email address
chmod +x init-certs.sh
./init-certs.sh your@email.com
```

What `init-certs.sh` does:
1. Installs certbot if not present
2. Stops the nginx container (frees port 80)
3. Runs `certbot certonly --standalone` for each domain
4. Starts `docker compose up -d` automatically when done

---

### Step 5 — Deploy on server

```bash
ssh -i ~/.ssh/id_rsa_fenix_screen root@146.190.200.50
cd /root/nobelproducts

# Load all .tar images and start all containers
./deploy.sh
```

What `deploy.sh` does:
1. Loads each `.tar` file with `docker load`
2. Runs `docker compose up -d` to start all services

To update a single service without full redeploy:

```bash
docker load -i images/dragon-screen-web.tar
docker compose up -d --no-deps dragon-screen-web
```

---

### Step 6 — Set up automatic certificate renewal (server — run once)

```bash
crontab -e
```

Add this line (runs every 60 days at 03:00):

```
0 3 */60 * * /root/nobelproducts/renew-certs.sh >> /var/log/renew-certs.log 2>&1
```

What `renew-certs.sh` does:
1. Stops the nginx container (frees port 80)
2. Runs `certbot renew --standalone`
3. Starts nginx again
4. Verifies each domain: cert file exists, days remaining, TLS handshake passes

Check renewal logs:

```bash
tail -f /var/log/renew-certs.log
```

---

## Day-to-day operations

### Redeploy one website

```bash
# Local — build and save the specific image
make build-dragon
make save-dragon

# Sync the new image to the server
cd web/deployments/digitalocean/server1
# Edit sync-prod.sh to include "./images"
./sync-prod.sh

# On the server
ssh -i ~/.ssh/id_rsa_fenix_screen root@146.190.200.50
cd /root/nobelproducts
docker load -i images/dragon-screen-web.tar
docker compose up -d --no-deps --force-recreate dragon-screen-web
```

### Enable a new website

1. Uncomment the service block in `docker-compose.yml`
2. Uncomment the upstream + server blocks in `nginx.conf`
3. Sync both files: `./sync-prod.sh`
4. On the server: obtain a cert for the new domain if not yet issued
5. Run `docker compose up -d` on the server

### View container logs

```bash
# All containers
docker compose logs -f

# One container
docker compose logs -f dragon-screen-web
docker compose logs -f nginx
```

### Check container status

```bash
docker compose ps
```

### Reload nginx config (without restart)

```bash
docker exec nginx nginx -s reload
```

### Manual cert check

```bash
certbot certificates
```

---

## Environment variables

Each website reads its runtime config from `environments/<name>/.env.prod`.
These files are **gitignored** (`.env*` pattern) and must be created manually on both local and server.

Example (copy and fill in for each site):

```bash
cp environments/dragon-screen/.env.example environments/dragon-screen/.env.prod
```

---

## Security notes

- `.env.prod` and `*.pem` files are gitignored — never commit them
- `/etc/letsencrypt` is mounted read-only (`:ro`) into the nginx container
- All HTTP traffic is hard-redirected to HTTPS with `return 301`
- TLS 1.0 / 1.1 are disabled; only TLSv1.2 and TLSv1.3 are allowed
