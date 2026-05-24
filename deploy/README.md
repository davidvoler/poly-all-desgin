# Polyglots — deploy_secure/

TLS-terminating nginx, three subdomains, port 443. The conf file is
written to match exactly what `certbot --nginx` produces on the
production box — locally we bind-mount `./certs/` at `/etc/letsencrypt`
so the same paths resolve.

## Local test on macOS

1. **Edit `/etc/hosts`** (`sudo nano /etc/hosts`) and add:

   ```
   127.0.0.1  www.polyglots.social app.polyglots.social dashboard.polyglots.social
   ```

2. **Generate self-signed certs** in the certbot-style layout:

   ```
   cd deploy_secure/certs
   ./generate-local.sh
   ```

   This creates `live/app.polyglots.social/{fullchain,privkey}.pem`
   with SANs for all three subdomains, plus `options-ssl-nginx.conf`
   and `ssl-dhparams.pem`.

3. **Start nginx**:

   ```
   cd ..
   docker compose up -d
   ```

4. **Verify with curl** (skip the browser cert warning):

   ```
   curl -kI http://www.polyglots.social/                   # → 301 to https
   curl -k  https://www.polyglots.social/       | head -2  # indigo  marketing
   curl -k  https://app.polyglots.social/       | head -2  # green   student app
   curl -k  https://dashboard.polyglots.social/ | head -2  # magenta dashboard
   ```

5. **Browser**: open the three HTTPS URLs. You'll get a self-signed
   cert warning the first time — proceed past it. The cert SAN covers
   all three names so one "trust" gesture is enough.

## Production deployment

The conf is drop-in for a box where `certbot --nginx` has already
issued a SAN cert for `app.polyglots.social` covering the three
subdomains. Two changes:

1. **Replace the certs bind-mount** in `docker-compose.yaml`:

   ```yaml
   - ./certs:/etc/letsencrypt:ro
   ```

   with:

   ```yaml
   - /etc/letsencrypt:/etc/letsencrypt:ro
   ```

2. **Get the cert** before bringing nginx up (one cert, three SANs —
   pick `app.polyglots.social` as the primary so the cert lives at
   the path the conf expects):

   ```
   certbot certonly --standalone \
       -d app.polyglots.social \
       -d www.polyglots.social \
       -d dashboard.polyglots.social
   ```

   Then `docker compose up -d`.

3. **Cert renewal**: certbot's systemd timer renews in-place. nginx
   needs an `nginx -s reload` to pick up the new cert; add a deploy
   hook:

   ```
   sudo certbot renew --deploy-hook "docker exec polyglots-nginx-tls nginx -s reload"
   ```

## Wiring real Flutter builds

```bash
cd ../dashboard      && flutter build web
cd ../poliglots_app  && flutter build web
```

Then uncomment the two lines in `docker-compose.yaml`:

```yaml
- ../dashboard/build/web:/usr/share/nginx/html/dashboard:ro
- ../poliglots_app/build/web:/usr/share/nginx/html/app:ro
```

`docker compose restart nginx` and the placeholders are gone.

## Adding api. / audio. subdomains

`nginx/polyglots.conf` has a commented `api.` block that proxies to
the `server` container. To use it, run this nginx in the same compose
network as the backend (either move the nginx service into the root
`docker-compose.yaml` or attach to its network as external).

## What's verified

`docker compose up -d` already passed these checks on this machine:

- `nginx -t` inside the container reports the config syntactically OK
- `http://*.polyglots.social/` returns `301` to `https://`
- Each HTTPS subdomain serves its placeholder page
- TLS handshake to an unknown Host header gets a 444 (connection
  closed cleanly)
- The presented cert SAN lists all three names
