# Validación · 2026-10-16
Realizado localmente:
- Sintaxis Python por AST; shell con sh -n; YAML de los tres Compose; sintaxis del guard Node con node --check.
- Todas las imágenes fijadas por digest, sin puertos de host en Compose base; app UID1001 y backend internal.
- configure.py crea .env 0600 y rechaza sobrescribir sin modificar el archivo.
- check_sqlite.py ejecutado contra una base SQLite temporal: quick_check, reconocimiento de un registro password activo ficticio, rechazo de auth inactivo y comprobación de que la lectura no cambió el archivo. El hash era una cadena de prueba, no una contraseña real ni un hash criptográficamente validado.
- CSV ficticio: suma decimal comprobada 85000.00; no se ejecutó el importador de Actual.
- Validador tar rechaza ../, rutas absolutas, enlaces y setuid.
- Con comandos Docker simulados: pausa/copia/reinicio, manifiesto y hashes, rechazo de archivo alterado, destino activo o volumen ocupado; recorrido de restauración de tar ficticio; reinicio tras fallo de copia y ausencia de completed en copia fallida.
- Integridad ZIP y exclusión de .env real, copias y cachés.

Las simulaciones verifican lógica de scripts y no ejecutan Docker, Actual, Caddy, SQLite nativo del servidor ni restauración de un presupuesto real. El guard Node solo recibió comprobación sintáctica: falta confirmar resolución de better-sqlite3, esquema del datastore, UID/permisos y arranque nativo en la imagen.

Pendiente: docs/ACEPTACION.md completo en VPS, Compose config con CLI real, descarga/arranque, Basic Auth + password nativo, HTTPS/aislamiento de navegador, CSV real, exportación/cifrado si se usa, sincronización desde perfiles separados y restauración funcional del presupuesto. No hay servicio publicado, banco conectado o integración Odoo instalada.
