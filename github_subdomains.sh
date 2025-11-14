#!/bin/bash

# GitHub Code Search - Subdomain Enumeration with API Token
# Searches GitHub repositories for subdomains related to target domain

GITHUB_TOKEN="${GITHUB_TOKEN:-ghp_TBb4fxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx}"

domain=""
output_file=""

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--output)
      output_file="$2"
      shift 2
      ;;
    -t|--token)
      GITHUB_TOKEN="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 <domain> [-o output_file] [-t token]"
      echo "  domain: Target domain"
      echo "  -o: Save output to file"
      echo "  -t: GitHub token (optional)"
      echo ""
      echo "Get token: https://github.com/settings/tokens"
      echo "Example: $0 example.com -o subdomains.txt -t ghp_xxxxx"
      exit 0
      ;;
    -*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      domain="$1"
      shift
      ;;
  esac
done

if [ -z "$domain" ]; then
  echo "Usage: $0 <domain> [-o output_file] [-t token]"
  exit 1
fi

echo -e "${BLUE}[*] GitHub Subdomain Enumeration${NC}"
echo -e "${BLUE}[*] Target: $domain${NC}"
echo ""

# Check for token
if [ -n "$GITHUB_TOKEN" ]; then
  headers=(-H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json")
  echo -e "${GREEN}[+] Using GitHub token (5000 requests/hour)${NC}"
else
  headers=(-H "Accept: application/vnd.github.v3+json")
  echo -e "${RED}[!] No API token - Limited to 60 requests/hour${NC}"
  echo -e "${YELLOW}[!] Get token: https://github.com/settings/tokens${NC}"
fi
echo ""

temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

# Function to extract subdomains from content
extract_subdomains() {
  local content="$1"
  local domain_to_match="$2"
  echo "$content" | grep -oE "[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.${domain_to_match}" | \
    grep -E "\.${domain_to_match}$"
}

# Function to check rate limit
check_rate_limit() {
  local response="$1"
  if echo "$response" | grep -q "API rate limit exceeded"; then
    echo -e "${RED}[!] Rate limit exceeded${NC}"
    return 1
  fi
  if echo "$response" | grep -q "Bad credentials"; then
    echo -e "${RED}[!] Invalid GitHub token${NC}"
    return 1
  fi
  return 0
}

# Function to search GitHub
search_github() {
  local query="$1"
  local description="$2"
  
  echo -e "${BLUE}[*] $description${NC}"
  
  local encoded_query=$(echo "$query" | sed 's/ /%20/g' | sed 's/"/%22/g')
  local api_url="https://api.github.com/search/code?q=${encoded_query}&per_page=30"
  
  response=$(curl -s "${headers[@]}" "$api_url" 2>/dev/null)
  
  if ! check_rate_limit "$response"; then
    return 1
  fi
  
  local total=$(echo "$response" | jq -r '.total_count' 2>/dev/null)
  if [ "$total" != "null" ] && [ -n "$total" ] && [ "$total" -gt 0 ]; then
    echo "    [+] Found $total results"
    
    # Process files
    local count=0
    echo "$response" | jq -r '.items[]?.html_url' 2>/dev/null | while read file_url; do
      if [ -z "$file_url" ] || [ "$file_url" = "null" ]; then
        continue
      fi
      
      # Convert to raw URL
      raw_url=$(echo "$file_url" | sed 's|github.com|raw.githubusercontent.com|; s|/blob/|/|')
      
      # Download content
      raw_content=$(curl -s -L "$raw_url" 2>/dev/null)
      if [ -n "$raw_content" ]; then
        extract_subdomains "$raw_content" "$domain" >> "$temp_file"
        count=$((count + 1))
      fi
      
      sleep 0.3
    done
    echo "    [+] Processed files"
  else
    echo "    [-] No results"
  fi
  
  return 0
}

# Strategy 1: Direct domain search
if ! search_github "\"$domain\"" "Strategy 1: Direct domain search"; then
  exit 1
fi
sleep 1

# Strategy 2: Common subdomain patterns
echo ""
echo -e "${BLUE}[*] Strategy 2: Common subdomain patterns${NC}"
for pattern in "api.$domain" "www.$domain" "dev.$domain" "staging.$domain" "test.$domain"; do
  echo "    [*] Pattern: $pattern"
  if ! search_github "\"$pattern\"" ""; then
    exit 1
  fi
  sleep 1
done

# Strategy 3: File extensions
echo ""
echo -e "${BLUE}[*] Strategy 3: Configuration files${NC}"
for ext in "js" "json" "yaml" "yml" "xml" "config" "env" "txt"; do
  echo "    [*] Extension: .$ext"
  if ! search_github "\"$domain\" extension:$ext" ""; then
    exit 1
  fi
  sleep 1
done

# Strategy 4: Common keywords
echo ""
echo -e "${BLUE}[*] Strategy 4: Keywords (dns, ssl, subdomain)${NC}"
for keyword in "dns" "ssl" "subdomain" "certificate"; do
  echo "    [*] Keyword: $keyword"
  if ! search_github "\"$domain\" $keyword" ""; then
    exit 1
  fi
  sleep 1
done

# Process results
echo ""
echo -e "${BLUE}[*] Processing results...${NC}"

if [ -s "$temp_file" ]; then
  subdomains=$(cat "$temp_file" | \
    grep -v "^$" | \
    grep -iE "\.${domain}$" | \
    sort -u)
  
  rm -f "$temp_file"
  
  if [ -z "$subdomains" ]; then
    echo -e "${YELLOW}[!] No subdomains found${NC}"
    [ -n "$output_file" ] && touch "$output_file"
    exit 0
  fi
  
  if [ -n "$output_file" ]; then
    echo "$subdomains" > "$output_file"
    echo -e "${GREEN}[+] Results saved to $output_file${NC}"
    echo -e "${GREEN}[+] Total unique subdomains: $(echo "$subdomains" | wc -l)${NC}"
  else
    echo ""
    echo "$subdomains"
    echo ""
    echo -e "${GREEN}[+] Total unique subdomains: $(echo "$subdomains" | wc -l)${NC}"
  fi
else
  rm -f "$temp_file"
  echo -e "${YELLOW}[!] No subdomains found${NC}"
  [ -n "$output_file" ] && touch "$output_file"
fi
