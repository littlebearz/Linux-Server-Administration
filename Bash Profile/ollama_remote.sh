#!/usr/bin/env bash
#
# ollama-remote.sh - Send a prompt to a remote Ollama server and stream the reply.
#
# All behaviour can be configured through environment variables (see README.md).
# Output is the model response only; everything else (logs, errors) goes to stderr.
#
# Usage:
#   ./ollama-remote.sh "Your prompt here"
#   OLLAMA_MODEL=llama3 ./ollama-remote.sh --host http://192.168.1.10:11434 "Hello"
#
set -Eeuo pipefail

# ---------------------------------------------------------------------------
# Configuration (overridable via environment variables)
# ---------------------------------------------------------------------------
OLLAMA_DEFAULT_HOST="eoli-12900k.bear.internal:11434"
OLLAMA_HOST="${OLLAMA_HOST:-$OLLAMA_DEFAULT_HOST}"
OLLAMA_MODEL="${OLLAMA_MODEL:-gpt-oss:latest}"
OLLAMA_FALLBACK_MODELS="${OLLAMA_FALLBACK_MODELS:-gemma4:latest qwen3-coder:latest}"
OLLAMA_TIMEOUT="${OLLAMA_TIMEOUT:-120}"
OLLAMA_LOG_FILE="${OLLAMA_LOG_FILE:-}"
LOG_LEVEL="${LOG_LEVEL:-info}"

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
_log() {
  local level="$1"
  shift
  local msg
  msg=$(printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*")
  printf '%s\n' "$msg" >&2
  if [[ -n "${OLLAMA_LOG_FILE:-}" ]]; then
    printf '%s\n' "$msg" >>"$OLLAMA_LOG_FILE"
  fi
}

log_error() { _log "ERROR" "$@"; }
log_warn() { _log "WARN" "$@"; }
log_info() {
  case "${LOG_LEVEL:-info}" in
    error|warn) return 0 ;;
  esac
  _log "INFO" "$@"
}

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
show_help() {
  cat <<'EOF'
Usage: ollama-remote.sh [options] "Your prompt"

Stream a completion from a remote Ollama server. The model reply is written to
stdout; logs and errors are written to stderr.

If the selected model is not available on the server, the script automatically
fails over to the models listed in OLLAMA_FALLBACK_MODELS (see below).

Options:
  -h, --help       Show this help message and exit
  -m, --model NAME Model to use (default: gpt-oss:latest)
      --host URL   Ollama server base URL (default: $OLLAMA_HOST)
      --no-time    Do not prepend the current local time to the prompt
  --               End of options; treat everything after as the prompt

Environment variables:
  OLLAMA_HOST           Ollama server base URL
  OLLAMA_MODEL          Primary model (default: gpt-oss:latest)
  OLLAMA_FALLBACK_MODELS
                        Space-separated models tried when the primary is not
                        available (default: "gemma4:latest qwen3-coder:latest")
  OLLAMA_TIMEOUT        cURL max time in seconds (default: 120)
  OLLAMA_LOG_FILE       Append logs to this file
  LOG_LEVEL             error | warn | info (default: info)

Examples:
  ./ollama-remote.sh "What is the weather like?"
  OLLAMA_MODEL=llama3 ./ollama-remote.sh --host http://localhost:11434 "Hi"
EOF
}

# ---------------------------------------------------------------------------
# Prompt and payload construction
# ---------------------------------------------------------------------------

# prepend_time "your prompt" -> "As of now, the local time is ... Your prompt"
prepend_time() {
  local prompt="$1"
  local now
  now=$(date +"%A, %B %d, %Y %H:%M:%S %Z")
  printf 'As of now, the local time is %s. %s\n' "$now" "$prompt"
}

# build_payload MODEL PROMPT -> valid JSON document for /api/generate
build_payload() {
  local model="$1"
  local prompt="$2"
  jq -cn \
    --arg model "$model" \
    --arg prompt "$prompt" \
    '{model: $model, prompt: $prompt, stream: true}'
}

# ---------------------------------------------------------------------------
# HTTP request
# ---------------------------------------------------------------------------

# normalize_host HOST -> ensures a URL scheme (defaults to http://)
normalize_host() {
  case "$1" in
    http://*|https://*) printf '%s\n' "$1" ;;
    *) printf 'http://%s\n' "$1" ;;
  esac
}

# request HOST MODEL PAYLOAD -> streams response lines to stdout
# Returns non-zero on transport/HTTP errors.
request() {
  local host="$1"
  local model="$2"
  local payload="$3"
  local url="${host%/}/api/generate"

  curl --fail-with-body -sS -N \
    --max-time "$OLLAMA_TIMEOUT" \
    -H 'Content-Type: application/json' \
    -d "$payload" \
    "$url"
}

# render_stream JSON_LINES -> prints only the response text (unbuffered,
# tokens concatenated with no separators).
# Prints "ERROR: ..." to stderr and exits non-zero if Ollama reports an error.
render_stream() {
  jq --unbuffered -j 'if has("error") then (("ERROR: " + .error) | halt_error) else .response // empty end'
}

# is_model_unavailable MESSAGE -> 0 if the error indicates a missing/not-pulled
# model (safe to fail over), 1 otherwise.
is_model_unavailable() {
  grep -Eiq 'not found|not pulled|does not exist|no such model|not available' <<<"$1"
}

# is_bind_address HOST -> 0 if the host is a wildcard bind address that cannot
# be reached as a client (e.g. OLLAMA_HOST=0.0.0.0 left over from a server setup)
is_bind_address() {
  [[ "$1" == "0.0.0.0" || "$1" == "0.0.0.0:"* ]]
}

# generate HOST MODEL PROMPT -> streams the reply to stdout.
# Exit status: 0 success; 1 hard failure; 2 model unavailable (caller may fail over).
generate() {
  local host="$1"
  local model="$2"
  local prompt="$3"
  local payload
  payload=$(build_payload "$model" "$prompt")

  log_info "POST ${host%/}/api/generate (model=$model)"

  local errfile
  errfile=$(mktemp "${TMPDIR:-/tmp}/ollama-remote.XXXXXX") || {
    log_error "could not create a temporary file"
    return 1
  }

  local -a statuses=()
  set +e
  set +o pipefail
  { request "$host" "$model" "$payload" | render_stream; } 2>"$errfile"
  statuses=("${PIPESTATUS[@]}")
  set -o pipefail
  set -e

  local curl_status="${statuses[0]:-0}"
  local render_status="${statuses[1]:-0}"

  if [[ $curl_status -eq 0 && $render_status -eq 0 ]]; then
    printf '\n'
    rm -f "$errfile"
    return 0
  fi

  local errtxt=""
  if [[ -s "$errfile" ]]; then
    errtxt=$(grep -m1 '^ERROR:' "$errfile")
    if [[ -z "$errtxt" ]]; then
      errtxt=$(<"$errfile")
    fi
  fi
  rm -f "$errfile"

  if is_model_unavailable "$errtxt"; then
    log_warn "model '$model' is not available: ${errtxt:-unknown reason}"
    return 2
  fi

  log_error "request for model '$model' failed (curl exit $curl_status, jq exit $render_status): ${errtxt:-no details}"
  return 1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  local model="$OLLAMA_MODEL"
  local host="$OLLAMA_HOST"
  local prepend_time_flag=1
  local prompt=""
  local positional=()

  while (($# > 0)); do
    case "$1" in
      -h|--help)
        show_help
        exit 0
        ;;
      -m|--model)
        [[ $# -ge 2 ]] || { log_error "option '$1' requires a value"; exit 2; }
        model="$2"
        shift 2
        ;;
      --host)
        [[ $# -ge 2 ]] || { log_error "option '$1' requires a value"; exit 2; }
        host="$2"
        shift 2
        ;;
      --no-time)
        prepend_time_flag=0
        shift
        ;;
      --)
        shift
        positional+=("$@")
        break
        ;;
      -*)
        log_error "unknown option: $1"
        show_help >&2
        exit 2
        ;;
      *)
        positional+=("$1")
        shift
        ;;
    esac
  done

  [[ -n "$host" ]] || { log_error "OLLAMA_HOST must not be empty"; exit 2; }
  if is_bind_address "$host"; then
    log_warn "OLLAMA_HOST '$host' is a wildcard bind address, not reachable as a client; using default host '$OLLAMA_DEFAULT_HOST'"
    host="$OLLAMA_DEFAULT_HOST"
  fi
  host=$(normalize_host "$host")
  [[ -n "$model" ]] || { log_error "model must not be empty"; exit 2; }

  prompt="${positional[*]}"
  if [[ -z "$prompt" ]]; then
    log_error "no prompt provided"
    show_help >&2
    exit 2
  fi

  if ((prepend_time_flag)); then
    prompt=$(prepend_time "$prompt")
  fi

  local -a models=("$model")
  local -a fallbacks=()
  read -r -a fallbacks <<<"$OLLAMA_FALLBACK_MODELS"
  models+=("${fallbacks[@]}")

  local rc=0
  for candidate in "${models[@]}"; do
    [[ -n "$candidate" ]] || continue
    log_info "attempting generation with model '$candidate'"
    rc=0
    generate "$host" "$candidate" "$prompt" || rc=$?
    if [[ $rc -eq 0 ]]; then
      exit 0
    elif [[ $rc -eq 2 ]]; then
      log_warn "model '$candidate' unavailable, trying the next one"
      continue
    else
      exit 1
    fi
  done

  log_error "all candidate models are unavailable"
  exit 1
}

if [[ "${BASH_SOURCE[0]:-}" == "$0" ]]; then
  main "$@"
fi
