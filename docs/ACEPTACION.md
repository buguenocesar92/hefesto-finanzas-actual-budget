# Aceptación en servidor
- Compose config --quiet sin errores; imágenes disponibles para la arquitectura; permisos del volumen y ejecución UID1001 correctos.
- Sin Basic Auth, gateway devuelve 401; contraseña incorrecta 401; correcta permite el flujo. App sin acceso directo público.
- En bootstrap privado: establecer password nativo, primer login, presupuesto y sincronización ficticios. Luego recrear solo con Compose base y comprobar que el guard permite inicio. Con volumen vacío y sin bootstrap, debe fallar.
- Por HTTPS público: sin errores de SharedArrayBuffer/COOP/COEP/worker; crear, abrir, editar, sincronizar y exportar. Probar navegador móvil y perfil nuevo.
- Importar CSV ficticio en cuenta con saldo cero y obtener saldo esperado 85000, con signos y fecha correctos. Probar categorías y búsqueda sin datos reales.
- Verificar que header auth y OpenID no están habilitados, y que una cabecera X-Actual-Password del cliente no abre acceso. No confundir Basic Auth con el password nativo.
- Si se usa cifrado, activarlo manualmente en un presupuesto de prueba, conservar clave y probar recuperación/exportación. No darlo por activado en todos los archivos.
- Pausar/recrear contenedores y confirmar persistencia. Exportar/sincronizar antes de respaldar; restaurar en proyecto nuevo con perfil limpio y revisar totales, archivos y contraseña.
- Confirmar que el cierre de sesión/retirada de datos locales cumple el uso en equipos compartidos. Basic Auth y la expiración de token no borran copias offline.
