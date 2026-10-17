# Integraciones y entrega de Hefesto
Odoo: usar Actual para presupuesto/seguimiento operativo y el sistema contable correspondiente para sus registros. No importar automáticamente cada movimiento como asiento. Un conector necesita definir cuentas, moneda, impuestos, estado, duplicados y autorización del responsable; no se incluye un flujo que publique asientos.

WordPress/WooCommerce: antes de cargar ventas/gastos, definir si se trasladan movimientos, liquidaciones de la pasarela o resúmenes para evitar duplicar importes. Esta entrega solo incluye un CSV ficticio y el flujo de importación manual; no accede a una tienda real.

API/CLI: Actual dispone de herramientas nativas para trabajar con presupuestos. Revisar sus versiones y cómo mantener password/token/contraseña de cifrado fuera del código. Con Basic Auth adicional, cada cliente debe soportar esa capa; este kit prioriza navegador. No deshabilitar la pasarela ni habilitar header auth indiscriminadamente para hacer funcionar una integración.

No hay conexión bancaria instalada ni recolección de credenciales bancarias. La red interna del servidor limita esas llamadas externas; habilitar una integración requiere otro cambio revisado y pruebas del proveedor concreto. No prometer soporte de bancos chilenos por incluir Actual.

Entrega al cliente: dominio, responsable, acceso por canal privado, ubicación del presupuesto/exportación, política de respaldo, prueba de recuperación y límites del soporte. Crear una instancia por cliente cuando deba existir aislamiento; este modo password no ofrece identidad separada para cada miembro.
