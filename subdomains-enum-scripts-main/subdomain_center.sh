#!/usr/bin/env bash
# subdomain-center-enum-noauth.sh
# Enumerate subdomains using the public https://api.subdomain.center/ endpoint (no auth).
# Usage: ./subdomain-center-enum-noauth.sh example.com [-o out.txt] [-e engine] [-h]

set -euo pipefail

DOMAIN=""
OUTPUT_FILE=""
ENGINE="cuttlefish"    # default engine (cuttlefish | octopus)
TRIES=5                # total attempts
TIMEOUT=15             # curl timeout in seconds
BACKOFF_BASE=2         # exponential backoff base
USER_AGENT="subdomain-center-enum/1.0 (+https://example.com)"

usage() {
  cat <<EOF
Usage: $0 <domain> [-o output_file] [-e engine] [-h]
  domain        : target domain (required)
  -o, --output  : save results to file
  -e, --engine  : engine (cuttlefish | octopus). Default: ${ENGINE}
  -h, --help    : show this message
Example:
  $0 example.com
  $0 example.com -o subdomains.txt -e octopus
EOF
  exit 1
}

if [ $# -lt 1 ]; then usage; fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
    -e|--engine) ENGINE="$2"; shift 2 ;;
    -h|--help) usage ;;
    -*)
      echo "Unknown option: $1"; usage ;;
    *)
      if [ -z "$DOMAIN" ]; then DOMAIN="$1"; shift; else echo "Unexpected: $1"; usage; fi
      ;;
  esac
done

if [ -z "$DOMAIN" ]; then echo "Error: domain is required."; usage; fi

# Dependencies
if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required. Install curl and retry."
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required. Install jq (apt/yum/brew) and retry."
  exit 2
fi

BASE_URL="https://api.subdomain.center/"
QUERY="?domain=${DOMAIN}&engine=${ENGINE}"
URL="${BASE_URL}${QUERY}"

echo "Querying public Subdomain Center for: ${DOMAIN}"
echo "Endpoint: ${URL}"
echo "Note: public endpoint is rate-limited; script will retry up to ${TRIES} times on empty/failed responses."

attempt=1
while [ $attempt -le $TRIES ]; do
  # Try to fetch
  response=$(curl -sS -A "${USER_AGENT}" --max-time "${TIMEOUT}" "${URL}" || true)

  if [ -z "${response}" ]; then
    echo "[attempt ${attempt}] Empty response from API."
  else
    # Is it valid JSON?
    if echo "${response}" | jq -e . >/dev/null 2>&1; then
      # If JSON array, check length
      is_array=$(echo "${response}" | jq 'type == "array"')
      if [ "${is_array}" = "true" ]; then
        count=$(echo "${response}" | jq 'length')
        if [ "$count" -gt 0 ]; then
          # Extract subdomains and de-duplicate
          subdomains=$(echo "${response}" | jq -r '.[]' | sed '/^\s*$/d' | sort -u)
          if [ -n "${OUTPUT_FILE}" ]; then
            printf "%s\n" "${subdomains}" > "${OUTPUT_FILE}"
            echo "Results saved to ${OUTPUT_FILE}"
            echo "Total unique subdomains found: $(echo "${subdomains}" | wc -l)"
          else
            printf "%s\n" "${subdomains}"
            echo "Total unique subdomains found: $(echo "${subdomains}" | wc -l)"
          fi
          exit 0
        else
          echo "[attempt ${attempt}] API returned an empty array (possible rate-limit or no results)."
        fi
      else
        echo "[attempt ${attempt}] API returned JSON that is not an array. Showing first lines:"
        echo "${response}" | sed -n '1,12p'
      fi
    else
      echo "[attempt ${attempt}] API returned non-JSON/malformed output (showing first lines):"
      echo "${response}" | sed -n '1,12p'
    fi
  fi

  # Retry logic: exponential backoff + small random jitter
  if [ $attempt -lt $TRIES ]; then
    backoff=$(( BACKOFF_BASE ** attempt ))
    jitter=$(( RANDOM % 3 ))   # 0-2 seconds jitter
    wait_time=$(( backoff + jitter ))
    echo "Retrying in ${wait_time}s... (attempt $((attempt+1))/${TRIES})"
    sleep "${wait_time}"
  fi
  attempt=$((attempt+1))
done

echo "Failed to retrieve subdomains after ${TRIES} attempts."
echo "If you repeatedly see empty arrays, the public endpoint may be rate-limited. Try again later or combine results with other passive sources."
exit 1
