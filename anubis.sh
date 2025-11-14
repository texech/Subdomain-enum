#!/usr/bin/env bash
set -euo pipefail

# Anubis Subdomain Enumeration Script (AnubisDB API)
# Fixed with correct API endpoint

# Initialize variables
domain=""
output_file=""

# Parse command line args
while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--output)
      output_file="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 <domain> [-o output_file]"
      echo "  domain: Target domain to enumerate subdomains"
      echo "  -o, --output: Save output to file"
      echo ""
      echo "Example: $0 example.com -o subdomains.txt"
      exit 0
      ;;
    -*)
      echo "Unknown option: $1"
      echo "Usage: $0 <domain> [-o output_file]"
      exit 1
      ;;
    *)
      domain="$1"
      shift
      ;;
  esac
done

# Validate domain input
if [ -z "${domain:-}" ]; then
  echo "Usage: $0 <domain> [-o output_file]"
  echo "Example: $0 example.com -o subdomains.txt"
  exit 1
fi

echo "Enumerating subdomains for $domain using AnubisDB API..."

# The correct endpoint according to GitHub documentation
# https://github.com/jonluca/Anubis-DB
# Endpoint: https://anubisdb.com/subdomains/{domain}
# Note: There's a 10,000 subdomain limit per domain and 2000 requests per 15 minutes

subdomains=""

# Try the correct endpoint
response=$(curl -s --connect-timeout 15 --max-time 30 \
  -H "Content-Type: application/json" \
  -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
  "https://anubisdb.com/subdomains/${domain}" 2>/dev/null)

# Check if response is not empty
if [ -n "$response" ]; then
  # Try to parse with jq first
  if command -v jq >/dev/null 2>&1; then
    subdomains=$(echo "$response" | jq -r '.[]?' 2>/dev/null | head -10000)
  fi
  
  # Fallback parsing if jq fails or is not available
  if [ -z "$subdomains" ]; then
    subdomains=$(echo "$response" | sed 's/\[//g; s/\]//g; s/"//g; s/,/\n/g' | head -10000)
  fi
fi

# Clean and validate subdomains
if [ -n "$subdomains" ]; then
  subdomains=$(echo "$subdomains" | \
    grep -v "^$" | \
    grep -E "^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$" | \
    grep -E "\.${domain}$" | \
    sort -u)
fi

# Check if any subdomains were found
if [ -z "$subdomains" ]; then
  echo "No subdomains found or API returned invalid response."
  # Create empty output file if specified
  if [ -n "${output_file:-}" ]; then
    touch "$output_file"
    echo "Empty results file created: $output_file"
  fi
  exit 0
fi

# Count subdomains
subdomain_count=$(echo "$subdomains" | wc -l)

# Output results
if [ -n "${output_file:-}" ]; then
  echo "$subdomains" > "$output_file"
  echo "Results saved to $output_file"
  echo "Total unique subdomains found: $subdomain_count"
else
  echo "$subdomains"
  echo "Total unique subdomains found: $subdomain_count"
fi
