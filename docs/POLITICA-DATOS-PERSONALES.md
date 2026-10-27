# Política de tratamiento de datos personales — Finanzas (Hefesto Studio)

Estado: vigente desde 2026-10-20. Responsable del tratamiento: el cliente que
opera el kit. Este documento describe qué datos guarda el kit, por qué, cuánto
tiempo los retiene y cómo se exercise los derechos del titular (Ley 21.719).

## 1. Qué datos guarda este kit

El kit de finanzas (Actual Budget) guarda, por presupuesto y por
movimiento:

- **Cuentas del presupuesto**: nombre de la cuenta, tipo, saldo y moneda.
- **Movimientos**: fecha, importe, cuenta de origen y destino, beneficiario,
  categoría, notas y etiquetas.
- **Archivos adjuntos**: comprobantes y documentos que el usuario adjunta a un
  movimiento (PDF, imagenes), con su contenido y su nombre.
- **Cuentas de usuario**: correo, hash de contraseña y token de sesión.
- **Cifrado del presupuesto**: clave maestra derivada de la contraseña nativa
  del usuario. Es la pieza que abre los budgets cifrados del cliente.
- **Copias locales de respaldo**: `backups/<timestamp>/` con el volumen de datos
  completo (`data.tar.gz`) y la configuración del kit.

Los importes, los movimientos y los comprobantes son datos financieros
personales: identifican la situación económica de una persona o de su
hogar.

## 2. Qué datos NO guarda este kit

- El `.env` **no** se copia en claro al respaldo: solo sus nombres de
  variable (`env.vars`) y, si hay un receptor `age` configurado, el `.env`
  cifrado (`env.age`). Ver `docs/CONTRATO-RESPALDO.md`, regla 5.
- El kit no guarda datos de tarjetas, cuentas bancarias ni cuentas
- El kit no envía los movimientos a servicios de terceros: todo es local al
  proyecto Compose.

## 3. Base legal y deberes

- **Minimización**: el kit guarda la estructura del presupuesto y los movimientos que el
  usuario registra. No pide ni almacena datos bancarios, tarjetas ni
  documentos de identidad, y no registra categorías ni notas fuera de las que
  el usuario escribe.
- **Finalidad**: registrar y consultar las finanzas del cliente. Los datos no se usan para otros fines ni se ceden a terceros.
- **Seguridad**: los respaldos se cifran en reposo con `age` hacia el destino del operador, la clave privada no está en este servidor, el `.env` nunca sale en claro y los presupuestos cifrados siguen cifrados en el respaldo.
- **Auditoría**: cada respaldo y cada restauración dejan registro en `logs/restore.log` con origen, sha256 verificado, destino y resultado. Es registro de actividades de tratamiento: no guarda valores de secretos ni importes.

## 4. Retención

| Dato | Dónde | Retención por defecto | Quién lo borra |
|---|---|---|---|
| Movimientos y cuentas | volumen `data` (SQLite) | mientras el cliente los mantenga en el presupuesto | el operador, desde la interfaz |
| Comprobantes adjuntos | volumen `data` | mientras el cliente los mantenga | el operador |
| Sesiones y usuarios | volumen `data` | mientras la cuenta exista | el operador |
| Respaldos en disco | `backups/<timestamp>/` | **a definir por el operador**; el kit no borra nada por su cuenta | el operador |
| Registro de auditoría | `logs/restore.log` | append-only; se trunca por política del cliente | el operador |

**El kit no borra respaldos ni datos por su cuenta.** Borrar es una decisión del
operador, porque un respaldo borrado no se recupera.

## 5. Derechos del titular (acceso, rectificación y supresión)

El cliente que opera el kit debe poder atender las solicitudes de sus
titulares sobre los datos financieros:

1. **Acceso**: exportar el presupuesto desde la interfaz y entregarlo a quien
   lo solicite, incluyendo movimientos y comprobantes.
2. **Rectificación**: editar o corregir un movimiento y sus etiquetas.
3. **Supresión**: eliminar el movimiento y, cuando corresponda, el presupuesto
   completo y los respaldos que lo contengan; dejar constancia en el registro
   de auditoría.
4. **Revocación del consentimiento**: si el tratamiento depende del
   consentimiento, eliminar la cuenta y cerrar la sesión.

El cifrado nativo del presupuesto no se abre ni se modifica con el respaldo:
restaurar datos no descifra presupuestos, y descifrar un presupuesto exige la
contraseña nativa del usuario.

## 6. Verificación

- `bats tests/backup_restore.bats` comprueba, con datos sintéticos, que el
  `.env` no queda en claro, que el manifiesto lleva las cinco claves, que un
  artefacto alterado se rechaza y que un destino no vacío aborta la
  restauración.
- `gitleaks` corre en CI sobre el repositorio y su historial.
