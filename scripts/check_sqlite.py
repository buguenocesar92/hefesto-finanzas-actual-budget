#!/usr/bin/env python3
"""Read-only health check of a locally extracted trusted server snapshot."""
import sqlite3,sys
from pathlib import Path
if len(sys.argv)!=2:raise SystemExit('Uso: python3 scripts/check_sqlite.py /ruta/data-extraido')
r=Path(sys.argv[1]).resolve();file=r/'server-files/account.sqlite'
if not file.is_file() or file.is_symlink() or r not in file.resolve().parents:raise SystemExit('Falta account.sqlite seguro')
con=sqlite3.connect(file.as_uri()+'?mode=ro',uri=True)
try:
    if con.execute('PRAGMA quick_check').fetchone()[0]!='ok':raise SystemExit('SQLite no integro')
    row=con.execute("SELECT active, extra_data FROM auth WHERE method='password'").fetchone()
    if not row or row[0]!=1 or not isinstance(row[1],str) or not row[1].startswith(('$argon2','$2a$','$2b$','$2y$')):raise SystemExit('No se encontro password activo reconocido')
    print('SQLite integro y password activo; no prueba la clave ni que los presupuestos puedan descifrarse.')
finally:con.close()
