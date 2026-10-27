#!/usr/bin/env python3
"""Respaldo de hefesto-finanzas (Actual Budget + SQLite).

El .env nunca se copia en claro: al respaldo solo van sus nombres (env.vars) y,
si hay receptor age, el .env cifrado (env.age). Ver docs/CONTRATO-RESPALDO.md.
"""
import datetime
import os
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import CONFIG, DATABASE, ROOT, SOFTWARE, VERSION, dc, safe_tar
from respaldo_contrato import (artefactos_presentes, escribir_manifiesto, ejecutar,
                               exportar_env, marcar_fallido)

os.umask(0o077)


def main():
    for n in CONFIG:
        if not (ROOT / n).is_file():
            raise SystemExit("Falta " + n)
    p = ROOT / "backups" / datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    p.mkdir(parents=True, mode=0o700)
    was_running = bool(dc("ps", "--status", "running", "-q", "app",
                          capture_output=True, text=True).stdout.strip())
    try:
        dc("stop", "--timeout", "60", "app")
        if dc("ps", "--status", "running", "-q", "app", capture_output=True, text=True).stdout.strip():
            raise SystemExit("app sigue activo; no se copia")
        with (p / "data.tar.gz").open("wb") as f:
            dc("run", "--rm", "--no-deps", "-T", "--entrypoint", "tar", "filetools",
               "-czf", "-", "-C", "/files", ".", stdout=f)
        safe_tar(p / "data.tar.gz")
        for n in CONFIG:
            dst = p / n
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / n, dst)
        meta = exportar_env(ROOT, p)
        escribir_manifiesto(p, SOFTWARE, VERSION, DATABASE, artefactos_presentes(p), extra=meta)
    except Exception:
        marcar_fallido(p, SOFTWARE, VERSION, DATABASE)
        raise
    finally:
        if was_running:
            dc("start", "app")
    print("Respaldo del servidor completado:", p)
    print("El .env no viaja en claro: solo env.vars y, si hay receptor age, env.age.")
    print("No incluye cambios aun no sincronizados del navegador.")
    return 0


if __name__ == "__main__":
    raise SystemExit(ejecutar(main))
