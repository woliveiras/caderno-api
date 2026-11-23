#!/bin/sh
set -eu

usage() {
    echo "Usage: $0 PORT baseline|status|count N" >&2
    exit 2
}

[ "$#" -ge 2 ] || usage
port=$1
case "$port" in
    ''|*[!0-9]*) usage ;;
esac
[ "${#port}" -le 5 ] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ] || usage

base="http://127.0.0.1:$port"
body=$(mktemp)
trap 'rm -f "$body"' EXIT
trap 'exit 1' HUP INT TERM

request() {
    method=$1
    path=$2
    expected_code=$3
    expected_body=$4
    code=$(curl --disable --noproxy '*' --silent --show-error --max-time 10 \
        --request "$method" --output "$body" --write-out '%{http_code}' "$base$path")
    if [ "$code" != "$expected_code" ] || ! grep -Eq "$expected_body" "$body"; then
        printf '%s %s: expected HTTP %s, got HTTP %s and body %s\n' \
            "$method" "$path" "$expected_code" "$code" "$(cat "$body")" >&2
        exit 1
    fi
    printf '%s %s: HTTP %s %s\n' "$method" "$path" "$code" "$(cat "$body")"
}

count() {
    request GET /visits 200 "^\{[[:space:]]*\"visits\"[[:space:]]*:[[:space:]]*$1[[:space:]]*\}$"
}

case "$2" in
    baseline)
        [ "$#" -eq 2 ] || usage
        request GET /status 404 '^\{[[:space:]]*"error"[[:space:]]*:[[:space:]]*"route not found"[[:space:]]*\}$'
        count 0
        request POST /visits 201 '^\{[[:space:]]*"id"[[:space:]]*:[[:space:]]*[1-9][0-9]*[[:space:]]*\}$'
        count 1
        count 1
        ;;
    status)
        [ "$#" -eq 2 ] || usage
        request GET /status 200 '^\{[[:space:]]*"status"[[:space:]]*:[[:space:]]*"ok"[[:space:]]*\}$'
        ;;
    count)
        [ "$#" -eq 3 ] || usage
        case "$3" in
            ''|*[!0-9]*) usage ;;
        esac
        count "$3"
        ;;
    *) usage ;;
esac
