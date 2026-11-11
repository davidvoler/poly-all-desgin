# Polyglots — deploy/

Single nginx container fronting three subdomains on one port. Use it
to verify routing locally before standing up the real instance.

## Local test on macOS

1. **Edit `/etc/hosts`** (`sudo nano /etc/hosts`) and add:

   ```
   127.0.0.1  www.polyglots.social app.polyglots.social dashboard.polyglots.social
   ```

   (All three names on one line is fine; nginx routes by the `Host`
   header at the HTTP layer, not by IP.)

2. **Start nginx**:

   ```
   cd deploy
   docker compose up
   ```

3. **Open in a browser** — each should show a differently-coloured
   placeholder so you can confirm the routing:

   - <http://www.polyglots.social>       → indigo "Polyglots"
   - <http://app.polyglots.social>       → green  "Student App"
   - <http://dashboard.polyglots.social> → magenta "School Dashboard"

   Any other Host header → connection dropped (the `default_server`
   block returns `444`).

## Wiring real Flutter builds

The compose file ships two commented bind-mounts. Build each Flutter
app and uncomment the matching line:

```bash
cd ../dashboard       && flutter build web
cd ../poliglots_app   && flutter build web
```

Then in `docker-compose.yaml`:

```yaml
- ../dashboard/build/web:/usr/share/nginx/html/dashboard:ro
- ../poliglots_app/build/web:/usr/share/nginx/html/app:ro
```

`docker compose restart nginx` and reload the page — the placeholders
are gone.

## Adding the API and audio subdomains

`nginx/polyglots.conf` has commented `api.` and `audio.` blocks that
`proxy_pass` to the existing `server` and `audio-server` containers
from the root `docker-compose.yaml`. To use them, run nginx in the
same compose network as those services (e.g. by adding the nginx
service to the root compose instead of this one, or by attaching to
the same external network).

## Production (HTTPS)

1. DNS: point all three subdomains at the instance's public IP.
2. Issue one Let's Encrypt cert covering all SANs:

   ```
   certbot certonly --nginx \
       -d www.polyglots.social \
       -d app.polyglots.social \
       -d dashboard.polyglots.social
   ```

3. In `nginx/polyglots.conf`, change each `listen 80;` to:

   ```
   listen 443 ssl http2;
   ssl_certificate     /etc/letsencrypt/live/polyglots.social/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/polyglots.social/privkey.pem;
   ```

4. Add an HTTP→HTTPS redirect block:

   ```
   server {
       listen 80;
       server_name www.polyglots.social app.polyglots.social dashboard.polyglots.social;
       return 301 https://$host$request_uri;
   }
   ```

5. In `docker-compose.yaml`, expose `443:443` and bind-mount
   `/etc/letsencrypt:/etc/letsencrypt:ro`.
