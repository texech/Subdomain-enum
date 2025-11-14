#!/bin/bash
# AlienVault OTX Subdomain Enumeration Script

# --- Configuration ---
OTX_KEY="e04170de7eef18bde132875c84caxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# --- Function to display usage instructions ---
show_usage() {
    echo "Usage: $0 <domain> [-o output_file]"
    echo "  domain:       The target domain you want to find subdomains for (e.g., tesla.com)."
    echo "  -o, --output: Optional. A file to save the list of subdomains."
    echo ""
    echo "Example: $0 example.com -o subdomains.txt"
}

# --- Check for Dependencies ---
if ! command -v curl &> /dev/null; then
    echo "Error: 'curl' is not installed. Please install it to continue." >&2
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed. It is required for parsing the API response." >&2
    exit 1
fi

# --- Parse Command Line Arguments ---
if [ "$#" -eq 0 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    show_usage
    exit 0
fi

domain="$1"
output_file=""

# Simple argument parsing to handle the optional output file
if [ "$2" == "-o" ] || [ "$2" == "--output" ]; then
    if [ -n "$3" ]; then
        output_file="$3"
    else
        echo "Error: Output file not specified after the -o flag." >&2
        show_usage
        exit 1
    fi
fi

echo "🔎 Enumerating subdomains for '$domain' using AlienVault OTX..."

# --- Perform the API Request ---
api_response=$(curl -s --connect-timeout 15 --max-time 30 \
    -H "X-OTX-API-KEY: ${OTX_KEY}" \
    "https://otx.alienvault.com/api/v1/indicators/domain/${domain}/passive_dns")

# --- Parse the Response ---
subdomains=$(echo "$api_response" | jq -r '.passive_dns[].hostname' 2>/dev/null | grep -E "\.$domain$" | sort -u)

# --- Output the Results ---
if [ -z "$subdomains" ]; then
    echo "❌ No subdomains found for '$domain'."
    if echo "$api_response" | jq -e '.detail == "Invalid token"' > /dev/null 2>&1; then
        echo "   Hint: The API reported an 'Invalid token' error. Please verify your OTX_API_KEY." >&2
    fi
    exit 1
fi

count=$(echo "$subdomains" | wc -l)
echo "✅ Success! Found $count unique subdomains."

if [ -n "$output_file" ]; then
    echo "$subdomains" > "$output_file"
    echo "📄 Results have been saved to '$output_file'."
else
    echo "--- Found Subdomains ---"
    echo "$subdomains"
fi
