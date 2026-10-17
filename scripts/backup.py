#!/usr/bin/env python3
import datetime,json,os,shutil
from common import ROOT,CONFIG,dc,sha,safe_tar
os.umask(0o077)
for n in CONFIG:
    if not (ROOT/n).is_file():raise SystemExit('Falta '+n)
p=ROOT/'backups'/datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ');p.mkdir(parents=True,mode=0o700)
was_running=bool(dc('ps','--status','running','-q','app',capture_output=True,text=True).stdout.strip())
try:
    dc('stop','--timeout','60','app')
    if dc('ps','--status','running','-q','app',capture_output=True,text=True).stdout.strip():raise SystemExit('app sigue activo; no se copia')
    with (p/'data.tar.gz').open('wb') as f:dc('run','--rm','--no-deps','-T','--entrypoint','tar','filetools','-czf','-','-C','/files','.',stdout=f)
    safe_tar(p/'data.tar.gz')
    for n in CONFIG:
        dst=p/n;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/n,dst)
    files=CONFIG+['data.tar.gz'];(p/'manifest.json').write_text(json.dumps({'product':'hefesto-finanzas','version':'26.10.0','status':'completed','sha256':{n:sha(p/n) for n in files}},indent=2))
    print('Respaldo del servidor completado:',p,'No incluye cambios aun no sincronizados del navegador.')
finally:
    if was_running:dc('start','app')
