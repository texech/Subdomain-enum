#!/bin/bash

# A simple, fast, and accurate crt.sh subdomain enumeration script.
# Version 4: Optimized for clean file output.

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Help Message ---
show_help() {
    # All help and error messages are sent to stderr
    echo "Usage: $0 <domain> [-o output_file]" >&2
    echo "  domain:       Target domain to enumerate (e.g., example.com)" >&2
    echo "  -o, --output: Save the clean list of subdomains to a file" >&2
    echo "  -h, --help:   Show this help message" >&2
    exit 0
}

# --- Argument Parsing ---
output_file=""
domain=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            output_file="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            show_help
            ;;
        *)
            if [ -z "$domain" ]; then
                domain="$1"
            fi
            shift
            ;;
    esac
done

# --- Input and Dependency Checks ---
if [ -z "$domain" ]; then
    echo -e "${RED}Error: No domain provided.${NC}" >&2
    show_help
fi

command -v jq >/dev/null 2>&1 || { echo -e "${RED}Error: jq is not installed. Please install it (e.g., sudo apt install jq).${NC}" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo -e "${RED}Error: curl is not installed. Please install it.${NC}" >&2; exit 1; }

# --- Main Logic ---
echo -e "${BLUE}Searching for subdomains of: ${GREEN}$domain${NC}" >&2

all_subdomains=$(curl -s "https://crt.sh/?q=%25.${domain}&output=json" | \
                 jq -r '.[].common_name, .[].name_value' | \
                 grep -oiE "([a-zA-Z0-9*._-]+\.)?${domain}" | \
                 sort -u)

subdomain_count=$(echo "$all_subdomains" | wc -l)

# --- Output Results ---
if [ -z "$all_subdomains" ] || [ "$subdomain_count" -eq 0 ]; then
    echo -e "${RED}No subdomains found for $domain.${NC}" >&2
    exit 1
fi

if [ -n "$output_file" ]; then
    # When -o is used, send ONLY the subdomains to the file.
    echo "$all_subdomains" > "$output_file"
    # Send all status messages to the console (stderr).
    echo -e "\n${GREEN}Total unique subdomains found: $subdomain_count${NC}" >&2
    echo -e "${GREEN}Results saved to: $output_file${NC}" >&2
else
    # If no output file, print everything to the console as before.
    echo "$all_subdomains"
    echo -e "\n${GREEN}Total unique subdomains found: $subdomain_count${NC}" >&2
fi
