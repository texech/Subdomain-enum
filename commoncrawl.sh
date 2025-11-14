#!/bin/bash

# Common Crawl Subdomain Enumeration Script
# Fixed to retrieve more subdomains

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

echo "Enumerating subdomains for $domain using Common Crawl..."

# Get the latest 3 crawl indexes (to get more results)
crawl_indexes=$(curl -s "https://index.commoncrawl.org/collinfo.json" | jq -r '.[0:3][].id' 2>/dev/null)

if [ -z "$crawl_indexes" ]; then
  echo "Failed to get Common Crawl indexes."
  # Create empty output file if specified
  if [ -n "$output_file" ]; then
    touch "$output_file"
    echo "Empty results file created: $output_file"
  fi
  exit 0
fi

# Temporary file to store all results
temp_file=$(mktemp)

# Query each index
for index in $crawl_indexes; do
  echo "Querying index: $index"
  
  # Query the index with wildcard subdomain search
  # The API supports pagination, so we'll try to get as many as possible
  curl -s --connect-timeout 10 --max-time 30 \
    "https://index.commoncrawl.org/${index}-index?url=*.${domain}/*&output=json&limit=10000" 2>/dev/null | \
    jq -r '.url' 2>/dev/null | \
    sed 's|https\?://||' | \
    sed 's|:[0-9]*||' | \
    cut -d'/' -f1 | \
    grep -iE "\.${domain}$" >> "$temp_file"
  
  # If jq fails, try without it (fallback)
  if [ ! -s "$temp_file" ]; then
    curl -s --connect-timeout 10 --max-time 30 \
      "https://index.commoncrawl.org/${index}-index?url=*.${domain}/*&output=text&fl=url&limit=10000" 2>/dev/null | \
      sed 's|https\?://||' | \
      sed 's|:[0-9]*||' | \
      cut -d'/' -f1 | \
      grep -iE "\.${domain}$" >> "$temp_file"
  fi
done

# Sort and deduplicate results
if [ -s "$temp_file" ]; then
  subdomains=$(cat "$temp_file" | sort -u)
  rm -f "$temp_file"
else
  rm -f "$temp_file"
  echo "No subdomains found or API returned invalid response."
  # Create empty output file if specified
  if [ -n "$output_file" ]; then
    touch "$output_file"
    echo "Empty results file created: $output_file"
  fi
  exit 0
fi

if [ -z "$subdomains" ]; then
  echo "No subdomains found or API returned invalid response."
  # Create empty output file if specified
  if [ -n "$output_file" ]; then
    touch "$output_file"
    echo "Empty results file created: $output_file"
  fi
  exit 0
fi

if [ -n "$output_file" ]; then
  echo "$subdomains" > "$output_file"
  echo "Results saved to $output_file"
  echo "Total unique subdomains found: $(echo "$subdomains" | wc -l)"
else
  echo "$subdomains"
  echo "Total unique subdomains found: $(echo "$subdomains" | wc -l)"
fi
