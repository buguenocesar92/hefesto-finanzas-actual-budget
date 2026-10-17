# Fuentes consultadas · 2026-10-16
- https://github.com/actualbudget/actual/releases/tag/v26.10.0
- https://github.com/actualbudget/actual/blob/v26.10.0/packages/sync-server/docker/alpine.Dockerfile
- https://github.com/actualbudget/actual/blob/v26.10.0/packages/sync-server/src/load-config.js
- https://github.com/actualbudget/actual/blob/v26.10.0/packages/sync-server/src/accounts/password.js
- https://github.com/actualbudget/actual/blob/v26.10.0/packages/sync-server/src/account-db.js
- https://actualbudget.org/docs/config/
- https://actualbudget.org/docs/install/docker/
- https://actualbudget.org/docs/getting-started/sync/
- https://actualbudget.org/docs/api/
- https://hub.docker.com/r/actualbudget/actual-server/tags
- https://caddyserver.com/docs/caddyfile/directives/basic_auth

La implementación vigente del servidor está en actualbudget/actual, no en el repositorio archivado actualbudget/actual-server. El nombre de imagen Docker actualbudget/actual-server continúa usándose. Imagen 26.10.0 fijada por digest en Compose.

El Dockerfile crea usuario UID1001 pero no lo selecciona con USER; este kit fija user 1001:1001 y prepara /data. No modifica el código de Actual; añade un guard anterior al arranque nativo. La disponibilidad de módulos y ejecución no root deben comprobarse con la imagen real. El guard usa better-sqlite3 desde /app/package.json, según el layout de esta versión.

El password nativo se almacena como hash en auth.extra_data y el modo password usa el propietario creado en primer login. La expiración se calcula en minutos en esta versión; 1440 corresponde a un día. Se incluye LICENSE-Actual.txt original. No se elimina atribución upstream ni se activan servicios comerciales externos.
