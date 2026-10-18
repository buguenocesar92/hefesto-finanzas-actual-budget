#!/usr/bin/env bash
# scripts/coolify-check.sh
# Verifica que compose.yaml cumpla el contrato para Coolify del MVP Hefesto.
# Contrato común: ver .superpowers/minimax/coolify/plan.md
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
# name: hardcoded a nivel raíz, en networks o en volumes está
# prohibido. Coolify pone el project name; un default en la
# variable cuenta como "fijo" y se rechaza.
# ---------------------------------------------------------------

# name: a nivel raíz.
if grep -E '^name:' "$ROOT/$COMPOSE_FILE" >/dev/null 2>&1; then
    NAME_LINE="$(grep -E '^name:' "$ROOT/$COMPOSE_FILE" || true)"
    if [[ -n "$NAME_LINE" ]]; then
        # Si la línea tiene un valor no parametrizado (no es ${VAR}), falla.
        if ! echo "$NAME_LINE" | grep -qE '^name:[[:space:]]+\$\{'; then
            record_fail "$COMPOSE_FILE" "name: raíz no parametrizado ($NAME_LINE)"
        # Si tiene default (${VAR:-default}), también falla.
        elif echo "$NAME_LINE" | grep -qE '^name:[[:space:]]+\$\{[^}]*:-\}'; then
            record_fail "$COMPOSE_FILE" "name: raíz con default (Coolify pone el project name)"
        fi
    fi
fi

# name: en networks o volumes (líneas con indentación ≥ 2 espacios).
# Buscar líneas que sean "name: valor_no_vacio" con esa indentación.
INDENTED_NAME="$(grep -E '^[[:space:]]{2,}name:[[:space:]]+' "$ROOT/$COMPOSE_FILE" || true)"
if [[ -n "$INDENTED_NAME" ]]; then
    # Verificar que no sea una interpolación ${VAR}.
    while IFS= read -r line; do
        if ! echo "$line" | grep -qE 'name:[[:space:]]+\$\{'; then
            record_fail "$COMPOSE_FILE" "name: hardcoded en networks/volumes ($line)"
        elif echo "$line" | grep -qE 'name:[[:space:]]+\$\{[^}]*:-\}'; then
            record_fail "$COMPOSE_FILE" "name: con default en networks/volumes ($line)"
        fi
    done <<< "$INDENTED_NAME"
fi

# ---------------------------------------------------------------
# Bloque B: renderizar el compose y validar lo dinámico.
# ---------------------------------------------------------------

TMP_ENV="$(mktemp -t coolify-check.XXXXXX.env)"
trap 'rm -f "$TMP_ENV"' EXIT

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

# 2) Renderizar el compose. stderr se descarta: solo stdout JSON nos sirve.
if ! RENDER="$(docker compose --project-directory "$ROOT" -f "$ROOT/$COMPOSE_FILE" --env-file "$TMP_ENV" config --format json 2>/dev/null)"; then
    echo "FAIL render: no se pudo renderizar $COMPOSE_FILE con valores ficticios"
    docker compose --project-directory "$ROOT" -f "$ROOT/$COMPOSE_FILE" --env-file "$TMP_ENV" config 2>&1 || true
    exit 1
fi

# 3) Validar contra el render JSON.
# Punto 1: en servicios sin profiles, no puede haber escapes del sandbox.
mapfile -t SERVICES < <(echo "$RENDER" | jq -r '.services | keys[]')
for svc in "${SERVICES[@]}"; do
    PROFILES_JSON="$(echo "$RENDER" | jq -c ".services[\"$svc\"].profiles // []")"
    if [[ "$PROFILES_JSON" != "[]" ]]; then
        note "servicio $svc tiene profiles, omitido del contrato"
        continue
    fi

    # ports
    PORTS_LEN="$(echo "$RENDER" | jq -r ".services[\"$svc\"].ports // [] | length")"
    if [[ "$PORTS_LEN" -gt 0 ]]; then
        record_fail "$svc" "tiene ports (debe ser expose)"
    fi

    # container_name
    CNAME="$(echo "$RENDER" | jq -r ".services[\"$svc\"].container_name // empty")"
    if [[ -n "$CNAME" ]]; then
        record_fail "$svc" "container_name '$CNAME'"
    fi

    # privileged, cap_add, devices
    for k in privileged cap_add devices; do
        V="$(echo "$RENDER" | jq -r ".services[\"$svc\"].$k // empty")"
        if [[ -n "$V" && "$V" != "null" && "$V" != "[]" ]]; then
            record_fail "$svc" "$k presente"
        fi
    done

    # network_mode, pid, ipc: host
    for k in network_mode pid ipc; do
        V="$(echo "$RENDER" | jq -r ".services[\"$svc\"].$k // empty")"
        if [[ "$V" == "host" ]]; then
            record_fail "$svc" "$k: host"
        fi
    done

    # security_opt unconfined
    if echo "$RENDER" | jq -e ".services[\"$svc\"].security_opt // [] | map(select(test(\"unconfined\"))) | length > 0" >/dev/null; then
        record_fail "$svc" "security_opt unconfined"
    fi

    # binds a docker.sock u otros sockets
    if echo "$RENDER" | jq -e ".services[\"$svc\"].volumes[]? | select(.type == \"bind\" and (.source == \"/var/run/docker.sock\" or (.source | test(\"^/var/run/.+\\\\.sock$\"))))" >/dev/null 2>&1; then
        record_fail "$svc" "bindeó socket"
    fi
done

# Punto 6: healthcheck que no dependa de credenciales en servicios web (app, gateway).
for svc in app gateway; do
    if ! echo "$RENDER" | jq -e ".services[\"$svc\"]" >/dev/null; then
        continue
    fi
    PROFILES_JSON="$(echo "$RENDER" | jq -c ".services[\"$svc\"].profiles // []")"
    if [[ "$PROFILES_JSON" != "[]" ]]; then
        continue
    fi
    if ! echo "$RENDER" | jq -e ".services[\"$svc\"].healthcheck" >/dev/null; then
        record_fail "$svc" "falta healthcheck que no dependa de credenciales"
    fi
done

if [[ "$FAIL" -ne 0 ]]; then
    echo "coolify-check: FAIL"
    exit 1
fi

echo "coolify-check: PASS"