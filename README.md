# Hefesto Finanzas · Actual Budget 26.10.0
Kit de despliegue del motor Actual Budget para presupuestos, cuentas y registro de movimientos. Útil para organizar la operación de un profesional o microempresa y ofrecer instalación, capacitación y mantenimiento desde Hefesto. Conserva la interfaz y la identidad upstream; no es un motor contable nuevo.

## Stack
Actual Budget nativo + SQLite/archivos de sincronización en /data + pasarela Caddy con contraseña. Imágenes fijadas por digest; Docker debe descargarlas. No necesita PostgreSQL ni Supabase: conectar otra base no reemplaza el almacenamiento nativo.

Este kit configura autenticación nativa por password, deshabilita los métodos header/OpenID y el proxy CORS y añade Basic Auth en la pasarela. El servidor se ejecuta como UID1001 con volumen preparado y red interna sin salida directa. No hay sincronización bancaria, OAuth, SMTP, servicios de IA o credenciales de bancos configurados.

La autenticación por contraseña del servidor comparte la identidad nativa de ese modo. La contraseña de pasarela también es compartida: esta entrega no proporciona un SaaS multicliente con cuentas/roles separados. Usar una instancia y proyecto Compose por cliente cuando se requiera separación.

## Requisitos y contenido
Linux con Docker Engine, Compose v2 y Python 3.11+; dominio HTTPS para publicar. Como presupuesto inicial de prueba, reservar 1 CPU, 512 MiB–1 GiB de RAM y espacio para datos y respaldo; medir la carga real. Navegador moderno con almacenamiento local y funciones de aislamiento/seguridad necesarias para Actual.

Incluye Compose base, bootstrap por túnel, ensayo con red interna, comprobación del datastore antes del inicio público, respaldo/validación/restauración y ejemplo CSV ficticio. No incluye imágenes Docker ni datos reales.

## Primera instalación privada
1. Descomprimir y entrar en esta carpeta. Ejecutar `python3 scripts/configure.py`: crea .env 0600 sin sobrescribir.
2. Crear un hash de acceso a la pasarela con entrada interactiva de contraseña:

```sh
docker run --rm -it caddy:2-alpine@sha256:d8542f48d34a9cf4e4c11a478865229840e87e4c96ea3f439101f31a5d35f75f caddy hash-password --algorithm bcrypt --bcrypt-cost 12
```

Pegar el hash en BASIC_AUTH_HASH conservando las comillas simples del ejemplo. BASIC_AUTH_USER admite 3–48 caracteres alfanuméricos, guion y guion bajo. Usar una contraseña larga, distinta del password nativo de Actual.
3. Validar y arrancar solo para setup:

```sh
docker compose -f compose.yaml -f compose.bootstrap.yaml config --quiet
docker compose -f compose.yaml -f compose.bootstrap.yaml up -d
```

4. Desde tu equipo abrir `ssh -L 8113:127.0.0.1:8113 usuario@servidor` y visitar http://localhost:8113. La excepción de contexto seguro de localhost permite la prueba; no usar una IP HTTP pública. Entrar por Basic Auth, definir el password nativo de Actual, completar el primer login y crear un presupuesto ficticio.
5. Elegir idioma y moneda desde la interfaz según la operación del cliente. Importar el CSV de demostración solo en una cuenta ficticia y revisar el resultado; ver docs/FLUJO.md. Probar cerrar/reabrir y sincronizar antes de avanzar.

El bootstrap permite el alta nativa inicial, pero no inventa tablas ni contraseñas en SQLite. El inicio base exige account.sqlite íntegro, un método password activo con hash reconocido y el usuario propietario del primer login. Si hay datos parciales o esquema diferente, falla para revisión; no borra el volumen. El validador no comprueba que recuerdas la contraseña ni que se puedan descifrar todos los presupuestos.

## Publicar en Coolify
Si el setup se hizo con Compose manual, respaldar y detener usando ambos archivos antes de pasar al recurso público. Coolify puede asignar nombres distintos a volúmenes: recuperar el respaldo en el volumen del recurso nuevo según docs/RESPALDO.md; no asumir que verá los datos del proyecto manual.

Importar la carpeta/repo privado como Docker Compose y seleccionar **compose.yaml**. Mantener el montaje ops/ en el checkout. Pegar usuario y bcrypt en variables del recurso; en el formulario, el hash se pega literal sin comillas envolventes. Asignar dominio HTTPS únicamente al servicio **gateway**, puerto **8080**. No publicar app, 5006 ni puertos del host. No utilizar compose.bootstrap.yaml en el servicio público.

TLS termina en Coolify. Usar dominio raíz, sin subruta. Caddy conserva los encabezados nativos que usa Actual, incluidos los de aislamiento; no se añade una CSP que rompa workers/WASM. Verificar en el navegador sincronización y ausencia de errores de seguridad de contexto/SharedArrayBuffer.

Una comprobación anónima de gateway devuelve 401 por diseño: no configurar un healthcheck que exija 200 sin credenciales. Probar acceso autenticado en privado y confirmar desde fuera que no existe acceso directo a app.

El contenedor base no tiene BOOTSTRAP_MODE activo. Para retirar bootstrap en una instalación manual: detener con ambos archivos y recrear usando solo compose.yaml; comprobar que desapareció el puerto 8113. Cambiar un archivo Compose no cambia por sí solo el entorno de un contenedor ya creado.

## Datos, claves y recuperación
/data conserva account.sqlite, archivos de usuarios y metadatos de sincronización. La contraseña nativa se gestiona por Actual y se conserva como hash en su base, no como texto en .env. .env contiene el hash de Basic Auth y la configuración de instancia; no guarda la contraseña nativa o de cifrado del presupuesto.

Actual mantiene también copias locales en los dispositivos. Sincronizar todos los clientes antes del respaldo del servidor y guardar exportaciones nativas desde la interfaz como copia adicional. El respaldo del VPS no incluye cambios que aún no se sincronizaron. No confundir sincronización con historial recuperable.

El cifrado de extremo a extremo es una opción nativa por presupuesto y se habilita manualmente. No está activado automáticamente por este kit ni se debe afirmar que todos los datos están cifrados por instalarlo. Guardar su contraseña de recuperación fuera del servidor y probar restauración/exportación. Tener un backup no sustituye la clave de cifrado.

La caducidad de sesión nativa se configura a 1440 minutos. No borra las copias locales del navegador. Basic Auth tampoco ofrece un logout fiable y un dispositivo puede conservar datos offline. Usar perfiles/equipos protegidos y revisar cómo cerrar/retirar datos locales antes de compartir un dispositivo.

## Alcance comercial e integraciones
Hefesto puede ofrecer instalación, diseño de categorías, acompañamiento de importación y operación. Este kit organiza presupuesto y movimientos; no implementa libros contables oficiales, conciliación automática, declaraciones tributarias, facturación SII o asientos de Odoo.

Para integrar otro sistema revisar la API/CLI nativa de Actual. La capa Basic Auth puede requerir soporte adicional en clientes de escritorio/API que no sean el navegador. No se ha instalado un conector REST genérico ni se han generado tokens para terceros. Ver docs/INTEGRACIONES.md.

Revisado localmente, sin Docker ni navegador real de la aplicación ejecutados. Completar docs/ACEPTACION.md antes de usar datos de clientes.
