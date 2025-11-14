#!/bin/bash

# Chaos (ProjectDiscovery) Subdomain Enumeration Script
API_KEY="1ffa192e-180x-xxxxxxxxxxxxxxxxxxxxxxxxx"

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

echo "Enumerating subdomains for $domain using Chaos..."

# Fetch subdomains
subdomains=$(curl -s -H "Authorization: $API_KEY" \
  "https://dns.projectdiscovery.io/dns/$domain/subdomains" \
  | jq -r '.subdomains[]?' 2>/dev/null \
  | sort -u)

if [ -z "$subdomains" ]; then
  echo "No subdomains found or API returned invalid response."
  exit 1
fi

# Append the domain to each subdomain
full_domains=$(echo "$subdomains" | awk -v dom="$domain" '{print $0 "." dom}')

# Output results
if [ -n "$output_file" ]; then
  echo "$full_domains" > "$output_file"
  echo "Results saved to $output_file"
  echo "Total unique subdomains found: $(echo "$full_domains" | wc -l)"
else
  echo "$full_domains"
  echo "Total unique subdomains found: $(echo "$full_domains" | wc -l)"
fi

