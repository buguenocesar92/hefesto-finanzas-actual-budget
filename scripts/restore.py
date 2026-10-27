#!/usr/bin/env python3
"""Restauracion de hefesto-finanzas en un destino nuevo y vacio.

Sin --confirmar CONFIRMAR_RESTAURACION no se escribe nada; con --dry-run se
simula. Valida manifiesto, sha256 y rutas tar antes de tocar el destino, exige
el volumen destino vacio y deja restore-report.json y auditoria.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import CONFIG, DATABASE, ROOT, SOFTWARE, VERSION, dc, sha, verify
from respaldo_contrato import (RespaldoError, auditar, ejecutar, escribir_informe,
                               opciones_restore)


def main():
    modo, origen = opciones_restore(sys.argv[1:])
    p = verify(origen)
    for n in CONFIG:
        if not (ROOT / n).is_file() or sha(ROOT / n) != sha(p / n):
            raise RespaldoError("Kit/configuracion distinta: " + n, 2)
    if modo == "dry-run":
        print("Simulacion: el respaldo es integro y no se escribio nada.")
        print("Para restaurar de verdad: --confirmar CONFIRMAR_RESTAURACION")
        return 0
    if dc("ps", "--services", "--status", "running", capture_output=True, text=True).stdout.strip():
        raise RespaldoError("Detener todos los servicios del destino", 5)
    if dc("run", "--rm", "--no-deps", "-T", "--entrypoint", "find", "filetools", "/files",
           "-mindepth", "1", "-print", "-quit", capture_output=True, text=True).stdout.strip():
        raise RespaldoError("Volumen destino no vacio; no se borra", 5)
    with (p / "data.tar.gz").open("rb") as f:
        dc("run", "--rm", "--no-deps", "-T", "--entrypoint", "tar", "filetools",
           "-xzf", "-", "-C", "/files", stdin=f)
    dc("run", "--rm", "--no-deps", "-T", "--entrypoint", "sh", "filetools",
       "-ec", "chown -R 1001:1001 /files; chmod 700 /files")
    escribir_informe(p, software=SOFTWARE, version=VERSION, database=DATABASE,
                     modo="confirmado", resultado="restaurado", destino=str(ROOT))
    auditar(ROOT, operacion="restore", kit=SOFTWARE, origen=str(p), destino=str(ROOT),
            resultado="restaurado")
    print("Datos restaurados. Revisar contrasena nativa, cifrado y sincronizacion primero "
          "en entorno privado.")
    return 0


if __name__ == "__main__":
    raise SystemExit(ejecutar(main))
