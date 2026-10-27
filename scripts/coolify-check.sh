#!/usr/bin/env bash
# scripts/coolify-check.sh
# Verifica que compose.yaml cumpla el contrato para Coolify del MVP Hefesto.
# Detalle del contrato y de las excepciones: ver README, sección
# «Despliegue en Coolify (MVP Hefesto)».
#
# Sale 0 si cumple, 1 con motivo si falla.
# Uso: bash scripts/coolify-check.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Solo el compose principal se valida contra el contrato de Coolify.
# compose.bootstrap.yaml es setup local por túnel SSH; compose.rehearsal.yaml es un
# fragmento que se combina en otro proyecto; ambos están documentados en el README.
COMPOSE_FILE="${COMPOSE_FILE:-compose.yaml}"

if [[ ! -f "$ROOT/$COMPOSE_FILE" ]]; then
    echo "Falta $COMPOSE_FILE en $ROOT"
    exit 1
fi

FAIL=0
record_fail() {
    # $1 sujeto (compose, servicio); $2 motivo.
    printf 'FAIL %s: %s\n' "$1" "$2"
    FAIL=1
}
note() { printf '  · %s\n' "$*"; }

# ---------------------------------------------------------------
# Bloque A: validación contra el YAML original.
# Cualquier "name:" a nivel raíz, en networks o en volumes es
# rechazado: Coolify pone el project name y los nombres por defecto
# de redes/volúmenes. La detección de networks/volumes se hace con
# PyYAML sobre el YAML original porque el render de docker compose
# genera nombres y no permite distinguir un "name:" explícito.
# ---------------------------------------------------------------

# name: a nivel raíz: cualquier línea que empiece con "name:" falla.
if grep -qE '^name:' "$ROOT/$COMPOSE_FILE"; then
    LINE="$(grep -E '^name:' "$ROOT/$COMPOSE_FILE" | head -1)"
    record_fail "$COMPOSE_FILE" "name: raíz presente ($LINE); Coolify pone el project name"
fi

# name: en networks/volumes: inspección estructural con PyYAML sobre el
# YAML original. Si PyYAML no está disponible o el YAML no parsea, hay
# que fallar con un motivo claro: el render de docker compose genera
# nombres por defecto y no permite distinguir un "name:" explícito,
# así que omitir la inspección abriría la puerta a name: hardcoded.
NM_PROBLEMS_OUT="$(mktemp -t nm-check.XXXXXX)"
NM_ERR="$(mktemp -t nm-check-err.XXXXXX)"
# Trap único: usa expansión ${VAR:-} porque TMP_ENV aún no existe en este
# punto y la inspección de PyYAML puede abortar antes de definirlo.
trap 'rm -f "${TMP_ENV:-}" "$NM_PROBLEMS_OUT" "$NM_ERR"' EXIT
if ! COMPOSE_YAML="$ROOT/$COMPOSE_FILE" python3 <<'PY' >"$NM_PROBLEMS_OUT" 2>"$NM_ERR"
import os, sys
try:
    import yaml
except ImportError as e:
    sys.stderr.write(f"PyYAML no disponible: {e}\n")
    sys.exit(2)
try:
    with open(os.environ["COMPOSE_YAML"]) as f:
        doc = yaml.safe_load(f) or {}
except Exception as e:
    sys.stderr.write(f"yaml parse: {e}\n")
    sys.exit(3)
problems = []
for kind in ("networks", "volumes"):
    section = doc.get(kind) or {}
    for key, value in section.items():
        if isinstance(value, dict) and "name" in value:
            problems.append(f"{kind}/{key} tiene name: {value['name']!r}")
if problems:
    print("\n".join(problems))
PY
then
    NM_REASON="$(tr '\n' ' ' < "$NM_ERR" | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
    record_fail "$COMPOSE_FILE" "no se pudo inspeccionar networks/volumes: ${NM_REASON}"
    rm -f "$NM_PROBLEMS_OUT" "$NM_ERR"
    exit 1
fi
rm -f "$NM_ERR"
NM_PROBLEMS="$(cat "$NM_PROBLEMS_OUT")"
rm -f "$NM_PROBLEMS_OUT"
if [[ -n "$NM_PROBLEMS" ]]; then
    while IFS= read -r line; do
        [[ -n "$line" ]] && record_fail "$COMPOSE_FILE" "name: en networks/volumes ($line); Coolify pone los nombres"
    done <<< "$NM_PROBLEMS"
fi

# ---------------------------------------------------------------
# Bloque B: renderizar el compose y validar lo dinámico.
# ---------------------------------------------------------------

TMP_ENV="$(mktemp -t coolify-check.XXXXXX.env)"
# El trap conserva la limpieza de NM_PROBLEMS_OUT y NM_ERR por si el
# script aborta en el bloque B después de pasar el A.
trap 'rm -f "$TMP_ENV" "$NM_PROBLEMS_OUT" "$NM_ERR"' EXIT

# 1) Generar .env temporal con valores ficticios por cada ${VAR} del compose.
mapfile -t VARS < <(grep -oE '\$\{[A-Z_][A-Z0-9_]*(:[-?][^}]*)?\}' "$ROOT/$COMPOSE_FILE" \
    | sed -E 's/^\$\{([A-Z_][A-Z0-9_]*).*/\1/' | sort -u)

{
    for var in "${VARS[@]}"; do
        case "$var" in
            *HOST*|*URL*|*DOMAIN*|*SITE*)
                echo "${var}=https://ejemplo.invalid"
                ;;
            BASIC_AUTH_HASH)
                # En un .env de compose, $ se escapa duplicándolo.
                echo "${var}=\$\$2a\$\$12\$\$abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01"
                ;;
            *)
                echo "${var}=x1234567890abcdef"
                ;;
        esac
    done
} > "$TMP_ENV"

# 2) Renderizar el compose. stderr se conserva para diagnóstico.
if ! RENDER="$(docker compose --project-directory "$ROOT" -f "$ROOT/$COMPOSE_FILE" --env-file "$TMP_ENV" config --format json 2>&1)"; then
    echo "FAIL render: no se pudo renderizar $COMPOSE_FILE con valores ficticios"
    echo "$RENDER" || true
    exit 1
fi
# Si docker compose mezcló advertencias con el JSON, quitar las WARNING y
# quedarse con el primer objeto JSON que empieza en la primera línea "{".
FIRST_JSON="$(printf '%s\n' "$RENDER" | awk '/^\{/{found=1} found{print} /^\}/{if (found) exit}')"
if [[ -z "$FIRST_JSON" ]]; then
    echo "FAIL render: salida sin JSON válido"
    echo "$RENDER" || true
    exit 1
fi
RENDER="$FIRST_JSON"

# 3) Validar contra el render JSON.
# Punto 1: en servicios sin profiles, no puede haber escapes del sandbox.
mapfile -t SERVICES < <(printf '%s\n' "$RENDER" | jq -r '.services | keys[]')
for svc in "${SERVICES[@]}"; do
    PROFILES_JSON="$(printf '%s\n' "$RENDER" | jq -c ".services[\"$svc\"].profiles // []")"
    if [[ "$PROFILES_JSON" != "[]" ]]; then
        note "servicio $svc tiene profiles, omitido del contrato"
        continue
    fi

    # ports
    PORTS_LEN="$(printf '%s\n' "$RENDER" | jq -r ".services[\"$svc\"].ports // [] | length")"
    if [[ "$PORTS_LEN" -gt 0 ]]; then
        record_fail "$svc" "tiene ports (debe ser expose)"
    fi

    # container_name
    CNAME="$(printf '%s\n' "$RENDER" | jq -r ".services[\"$svc\"].container_name // empty")"
    if [[ -n "$CNAME" ]]; then
        record_fail "$svc" "container_name '$CNAME'"
    fi

    # privileged, cap_add, devices
    for k in privileged cap_add devices; do
        V="$(printf '%s\n' "$RENDER" | jq -r ".services[\"$svc\"].$k // empty")"
        if [[ -n "$V" && "$V" != "null" && "$V" != "[]" ]]; then
            record_fail "$svc" "$k presente"
        fi
    done

    # network_mode, pid, ipc: host
    for k in network_mode pid ipc; do
        V="$(printf '%s\n' "$RENDER" | jq -r ".services[\"$svc\"].$k // empty")"
        if [[ "$V" == "host" ]]; then
            record_fail "$svc" "$k: host"
        fi
    done

    # security_opt unconfined
    if printf '%s\n' "$RENDER" | jq -e ".services[\"$svc\"].security_opt // [] | map(select(test(\"unconfined\"))) | length > 0" >/dev/null; then
        record_fail "$svc" "security_opt unconfined"
    fi

    # binds a docker.sock u otros sockets
    if printf '%s\n' "$RENDER" | jq -e ".services[\"$svc\"].volumes[]? | select(.type == \"bind\" and (.source == \"/var/run/docker.sock\" or (.source | test(\"^/var/run/.+\\\\.sock$\"))))" >/dev/null 2>&1; then
        record_fail "$svc" "bindeó socket"
    fi
done

# Punto 6: healthcheck que no dependa de credenciales en servicios web (gateway).
# El contrato exige healthcheck solo en el servicio web que Coolify expone,
# que es gateway. app no se valida porque su check depende del endpoint
# /health interno y de la imagen upstream; se documenta en el README.
svc=gateway
if printf '%s\n' "$RENDER" | jq -e ".services[\"$svc\"]" >/dev/null; then
    PROFILES_JSON="$(printf '%s\n' "$RENDER" | jq -c ".services[\"$svc\"].profiles // []")"
    if [[ "$PROFILES_JSON" == "[]" ]]; then
        if ! printf '%s\n' "$RENDER" | jq -e ".services[\"$svc\"].healthcheck" >/dev/null; then
            record_fail "$svc" "falta healthcheck que no dependa de credenciales"
        fi
    fi
fi

if [[ "$FAIL" -ne 0 ]]; then
    echo "coolify-check: FAIL"
    exit 1
fi

echo "coolify-check: PASS"
