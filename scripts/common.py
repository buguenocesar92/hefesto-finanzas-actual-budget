import hashlib,json,subprocess,tarfile
from pathlib import Path,PurePosixPath
ROOT=Path(__file__).resolve().parents[1]
CONFIG=['.env','compose.yaml','compose.bootstrap.yaml','compose.rehearsal.yaml','ops/Caddyfile','ops/start.sh','ops/gateway-start.sh','ops/actual-config.json','ops/check-data.cjs']
def dc(*a,**kw):return subprocess.run(['docker','compose','--project-directory',str(ROOT),'-f',str(ROOT/'compose.yaml'),*a],check=True,**kw)
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def safe_tar(path):
    names=set();total=0
    with tarfile.open(path,'r|gz') as tf:
        for m in tf:
            n=PurePosixPath(m.name)
            if n.is_absolute() or '..' in n.parts or not (m.isdir() or m.isfile()) or m.mode&0o6000:raise SystemExit('Tar con ruta, modo o tipo no admitido')
            if str(n) in names:raise SystemExit('Entrada duplicada')
            names.add(str(n));total+=m.size
            if len(names)>1000000 or total>100*1024**3:raise SystemExit('Tar supera limites de este kit')
def verify(folder):
    p=Path(folder).resolve();m=json.loads((p/'manifest.json').read_text())
    if (m.get('product'),m.get('version'),m.get('status'))!=('hefesto-finanzas','26.10.0','completed'):raise SystemExit('Manifest incorrecto')
    if set(m.get('sha256',{}))!=set(CONFIG+['data.tar.gz']):raise SystemExit('Lista inesperada')
    for n,digest in m['sha256'].items():
        f=p/n
        if f.is_symlink() or not f.is_file() or p not in f.resolve().parents or sha(f)!=digest:raise SystemExit('Checksum/ruta incorrecto: '+n)
    safe_tar(p/'data.tar.gz');return p
