#!/bin/bash
# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--output)
      output_file="$2"
      shift # past argument
      shift # past value
      ;;
    -h|--help)
      echo "Usage: $0 <domain> [-o output_file]"
      echo "  domain: Target domain to enumerate"
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

# Check if domain is provided
if [ -z "$domain" ]; then
  echo "Usage: $0 <domain> [-o output_file]"
  echo "Example: $0 target.com -o results.txt"
  exit 1
fi

echo "Enumerating $domain..."

subdomains=$(curl -s "https://api.certspotter.com/v1/issuances?domain=${domain}&include_subdomains=true&expand=dns_names" \
  | jq -r '.[].dns_names[]' 2>/dev/null \
  | sed 's/^\*\.\?//' \
  | grep -E "\.${domain}$" \
  | sort -u)

if [ -z "$subdomains" ]; then
  echo "No subdomains found or API returned invalid response."
  exit 1
fi

# Output results
if [ -n "$output_file" ]; then
  echo "$subdomains" > "$output_file"
  echo "Results saved to $output_file"
  echo "Total unique subdomains found: $(echo "$subdomains" | wc -l)"
else
  echo "$subdomains"
  echo "Total unique subdomains found: $(echo "$subdomains" | wc -l)"
fi
