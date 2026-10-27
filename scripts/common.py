import hashlib
import json
import subprocess
import sys
import tarfile
from pathlib import Path, PurePosixPath

sys.path.insert(0, str(Path(__file__).resolve().parent))
from respaldo_contrato import ejecutar_check

ROOT = Path(__file__).resolve().parents[1]
SOFTWARE = "hefesto-finanzas"
VERSION = "26.10.0"
DATABASE = "sqlite"
# Configuracion que viaja en el respaldo. El .env NO viaja: solo sus nombres.
CONFIG = ["compose.yaml", "compose.bootstrap.yaml", "compose.rehearsal.yaml",
          "ops/Caddyfile", "ops/start.sh", "ops/gateway-start.sh",
          "ops/actual-config.json", "ops/check-data.cjs"]


def dc(*a, **kw):
    return subprocess.run(["docker", "compose", "--project-directory", str(ROOT),
                           "-f", str(ROOT / "compose.yaml"), *a], check=True, **kw)


def sha(p):
    with p.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()


def safe_tar(path):
    names = set()
    total = 0
    with tarfile.open(path, "r|gz") as tf:
        for m in tf:
            n = PurePosixPath(m.name)
            if n.is_absolute() or ".." in n.parts or not (m.isdir() or m.isfile()) or m.mode & 0o6000:
                raise SystemExit("Tar con ruta, modo o tipo no admitido")
            if str(n) in names:
                raise SystemExit("Entrada duplicada")
            names.add(str(n))
            total += m.size
            if len(names) > 1000000 or total > 100 * 1024 ** 3:
                raise SystemExit("Tar supera limites de este kit")


def verify(folder):
    """Verifica manifiesto, checksums, cobertura y ausencia de secretos en claro."""
    p = Path(folder).resolve()
    ejecutar_check(str(p), SOFTWARE, VERSION, DATABASE)
    safe_tar(p / "data.tar.gz")
    return p
