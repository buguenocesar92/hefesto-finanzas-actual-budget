#!/usr/bin/env python3
"""Verificacion de integridad de un respaldo de hefesto-finanzas.

Codigos de salida: 0 integro, 1 uso, 2 integridad o manifiesto invalido,
4 material sensible en claro dentro del respaldo.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import verify
from respaldo_contrato import ejecutar


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Uso: python3 scripts/check_backup.py /ruta/respaldo")
    verify(sys.argv[1])
    print("Manifiesto, checksums, rutas tar y ausencia de secretos en claro verificados.")
    print("Falta la recuperacion real del presupuesto: no basta con que la base pase quick_check.")
    return 0


if __name__ == "__main__":
    raise SystemExit(ejecutar(main))
