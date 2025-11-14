#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 <domain> [-o output_file]"
    echo "Example: $0 example.com"
    echo "Example: $0 example.com -o subdomains.txt"
    echo ""
    echo "This script extracts subdomains from AbuseIPDB WHOIS data"
    echo "By default, outputs to terminal. Use -o to save to file."
    exit 1
}

# Parse command line arguments
TARGET_DOMAIN=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -o)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [ -z "$TARGET_DOMAIN" ]; then
                TARGET_DOMAIN="$1"
            else
                echo "Error: Unknown argument: $1"
                usage
            fi
            shift
            ;;
    esac
done

# Check if domain argument is provided
if [ -z "$TARGET_DOMAIN" ]; then
    usage
fi

# Validate domain format (basic check)
if [[ ! "$TARGET_DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    echo "Error: Invalid domain format: $TARGET_DOMAIN"
    exit 1
fi

echo "[+] Target domain: $TARGET_DOMAIN" >&2
echo "[+] Fetching subdomain data from AbuseIPDB..." >&2

# Extract subdomains directly using curl and command line tools
{
    echo "$TARGET_DOMAIN"  # Include main domain
    
    curl -s "https://www.abuseipdb.com/whois/${TARGET_DOMAIN}" \
         -H "user-agent: firefox" \
         -b "abuseipdb_session=" | \
    grep -A 2000 -i "subdomains" | \
    grep -oP '<li>[^<]+</li>' | \
    sed 's/<li>//g; s/<\/li>//g' | \
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | \
    grep -v '^[[:space:]]*$' | \
    grep -v "^client" | \
    grep -E '^[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]$|^[a-zA-Z0-9]$' | \
    while read -r subdomain; do
        if [ -n "$subdomain" ]; then
            echo "${subdomain}.${TARGET_DOMAIN}"
        fi
    done
    
} | sort -u | {
    if [ -n "$OUTPUT_FILE" ]; then
        # Save to file
        tee "$OUTPUT_FILE"
        echo "[+] Results saved to: $OUTPUT_FILE" >&2
    else
        # Output to terminal
        cat
    fi
}

# Count results and show summary
if [ -n "$OUTPUT_FILE" ]; then
    count=$(wc -l < "$OUTPUT_FILE")
    echo "[+] Total domains/subdomains: $count" >&2
else
    echo "" >&2
    echo "[+] Use -o filename.txt to save results to file" >&2
fi
