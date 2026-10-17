# Configuración funcional y demostración
## Presupuesto inicial
Crear un presupuesto de prueba y elegir la moneda adecuada. Para trabajar en pesos chilenos, confirmar cómo se muestran y se importan los importes antes de usar datos reales. Este ejemplo no hace conversiones monetarias ni cambia la precisión del motor.

Crear cuentas ficticias por separado: banco, caja y, si corresponde, otra cuenta de prueba. Registrar sus saldos iniciales desde una fuente comprobada; no inferirlos del CSV parcial. Configurar categorías con el responsable del negocio:
- Ingresos: servicios, proyectos, otros ingresos.
- Operación: hosting, software, comunicaciones, arriendo, servicios externos.
- Planificación: mantenimiento y renovación de equipos, reservas definidas por el responsable.

Son una propuesta organizativa; no se crean mediante seed ni constituyen una clasificación tributaria.

## CSV de prueba
examples/movimientos-demo.csv contiene dos movimientos ficticios con fecha ISO, texto y monto con punto decimal. En una cuenta ficticia con saldo inicial cero, usar la importación CSV nativa y mapear Date → fecha, Payee → beneficiario, Notes → notas y Amount → importe. Revisar formato de fecha, separador decimal y signo en la vista previa.

Los valores esperados son ingreso 100000 y salida 15000; el saldo resultante debe ser 85000 en la moneda elegida. Si el preview interpreta distinto el separador o invierte signos, corregir el mapeo antes de confirmar. No se multiplica por centavos ni se aplica tipo de cambio en este archivo.

Clasificar ambos movimientos y verificar totales, búsqueda y edición. No repetir el import sobre una cuenta real esperando deduplicación automática: comprobar el comportamiento y usar identificadores/origen cuando el flujo nativo lo soporte.

## Rutina de operación
Revisar importación con el responsable, comprobar saldos contra la fuente, clasificar pendientes, sincronizar y guardar exportación nativa. Conservar un registro del origen y fecha de los archivos importados. No copiar documentos bancarios o credenciales a repositorios del kit.

Demostración a un cliente: crear cuenta ficticia → importar dos movimientos → clasificar → revisar presupuesto → sincronizar → exportar → abrir desde un perfil de prueba autorizado. No usar la economía personal de otra persona como material de demo.
