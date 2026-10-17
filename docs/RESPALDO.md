# Respaldo y recuperación
## Antes de copiar
Confirmar sincronización de los dispositivos. Exportar el presupuesto desde la interfaz y conservar esa copia de forma segura. Si existe cifrado nativo, guardar la contraseña en una bóveda separada y probar que la exportación/restauración prevista funciona. No enviar contraseñas junto con el backup.

`python3 scripts/backup.py` pausa app hasta 60 segundos, comprueba que se detuvo, copia todo el volumen /data con tar y configuración, valida rutas y escribe manifiesto con SHA-256 solo al completar. Finalmente inicia app si antes estaba activo. Gateway puede mostrar 502 durante la pausa. No ejecutar al mismo tiempo una actualización, otra copia o restauración.

`python3 scripts/check_backup.py /ruta/respaldo` comprueba manifiesto, hashes y tar. Rechaza rutas absolutas/../, enlaces, dispositivos, duplicados y modos setuid/setgid; límites de 1 millón de entradas y 100 GiB expandidos. Los hashes detectan corrupción, no prueban autenticidad. La copia contiene sesiones, hashes y datos potencialmente sin cifrado: guardarla cifrada fuera del servidor con permisos y retención acordados.

No incluye datos solo locales del navegador, exportaciones guardadas en otros equipos, imágenes Docker, DNS o configuración del proxy Coolify.

## Recuperar sin sobrescribir
1. Usar esta misma versión de kit/imagen en una carpeta nueva y un proyecto Compose distinto. Crear .env para gateway con configure.py o recuperar una copia segura y cambiar COMPOSE_PROJECT_NAME, por ejemplo hefesto-finanzas-ensayo. El password de pasarela puede cambiar; el nativo y el cifrado del presupuesto siguen siendo los del dato recuperado.
2. Mantener todos los servicios del destino detenidos y el volumen nuevo vacío. El script no borra un volumen ocupado. No apuntar al proyecto de producción.
3. Ejecutar `python3 scripts/restore.py /ruta/respaldo`. Verifica archivos/versión y restaura datos, luego prepara UID1001. No inicia automáticamente. Si una extracción falla parcialmente, investigar y repetir en un destino nuevo.
4. Arrancar primero de forma privada:

```sh
docker compose -f compose.yaml -f compose.bootstrap.yaml -f compose.rehearsal.yaml up -d
```

La red de ensayo es interna y los puertos solo están en localhost. El override permite el diagnóstico nativo; no debe usarse para saltarse errores sobre datos reales. Probar desde un perfil de navegador **nuevo**, con las contraseñas correspondientes, y evitar conectar dispositivos de producción durante el ensayo para no sincronizar estados diferentes.
5. Confirmar archivos, cuentas, movimientos, categorías, totales y capacidad de exportar/descifrar. No basta que el servidor arranque o que la base pase quick_check. Salir del bootstrap y confirmar que el inicio base valida el datastore.

Opcional: si se extrajo manualmente una copia de confianza del volumen, `python3 scripts/check_sqlite.py /ruta/data-extraido` abre account.sqlite en solo lectura y revisa integridad/método password. No descifra presupuestos, no valida tokens ni sustituye la prueba funcional. No ejecutar sobre archivos descargados de personas desconocidas.

## Actualizaciones
Respaldar y exportar primero. Revisar notas de versión, cambiar etiqueta y digest juntos, probar en copia y ejecutar aceptación. Si hay migraciones, no asumir que una imagen anterior podrá leer los datos nuevos: usar un respaldo de la versión anterior para revertir. No se programan copias externas ni actualizaciones automáticas en esta entrega.
