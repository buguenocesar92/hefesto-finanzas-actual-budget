#!/usr/bin/env python3
import sys
from common import ROOT,CONFIG,dc,sha,verify
if len(sys.argv)!=2:raise SystemExit('Uso: python3 scripts/restore.py /ruta/respaldo')
p=verify(sys.argv[1])
for n in CONFIG:
    if n=='.env':continue
    if not (ROOT/n).is_file() or sha(ROOT/n)!=sha(p/n):raise SystemExit('Kit/configuracion distinta: '+n)
if dc('ps','--services','--status','running',capture_output=True,text=True).stdout.strip():raise SystemExit('Detener todos los servicios del destino')
if dc('run','--rm','--no-deps','-T','--entrypoint','find','filetools','/files','-mindepth','1','-print','-quit',capture_output=True,text=True).stdout.strip():raise SystemExit('Volumen destino no vacio; no se borra')
with (p/'data.tar.gz').open('rb') as f:dc('run','--rm','--no-deps','-T','--entrypoint','tar','filetools','-xzf','-','-C','/files',stdin=f)
dc('run','--rm','--no-deps','-T','--entrypoint','sh','filetools','-ec','chown -R 1001:1001 /files; chmod 700 /files')
print('Datos restaurados. Revisar contrasena nativa, cifrado y sincronizacion primero en entorno privado.')
