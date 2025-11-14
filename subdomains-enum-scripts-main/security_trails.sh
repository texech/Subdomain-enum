#!/bin/bash

# SecurityTrails Subdomain Enumeration Script
API_KEY="t5gB6TXuM-Xy4xxxxxxxxxxxxxxxxxxxx"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--output)
      output_file="$2"
      shift
      shift
      ;;
    -h|--help)
      echo "Usage: $0 <domain> [-o output_file]"
      echo "  domain: Target domain to enumerate subdomains"
      echo "  -o, --output: Save output to file"
      exit 0
      ;;
    -*)
      echo "Unknown option $1"
      echo "Usage: $0 <domain> [-o output_file]"
      exit 1
      ;;
    *)
      domain="$1"
      shift
      ;;
  esac
done

if [ -z "$domain" ]; then
  echo "Usage: $0 <domain> [-o output_file]"
  echo "Example: $0 target.com -o subdomains.txt"
  exit 1
fi

echo "Enumerating subdomains for $domain using SecurityTrails..."
subdomains=$(curl -s -H "APIKEY: $API_KEY" \
  "https://api.securitytrails.com/v1/domain/$domain/subdomains" \
  | jq -r '.subdomains[]' 2>/dev/null \
  | sed "s/$/.${domain}/" \
  | sort -u)

if [ -z "$subdomains" ]; then
  echo "No subdomains found or API returned invalid response."
  exit 1
fi

if [ -n "$output_file" ]; then
  echo "$subdomains" > "$output_file"
  echo "Results saved to $output_file"
  echo "Total unique subdomains found: $(echo "$subdomains" | wc -l)"
else
  echo "$subdomains"
  echo "Total unique subdomains found: $(echo "$subdomains" | wc -l)"
fi
