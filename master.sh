#!/bin/bash

# Master Subdomain Enumeration Script
# Runs all available subdomain enumeration tools and scripts
# Version 1.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
VERBOSE=0
OUTPUT_FILE=""
DOMAIN=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=$(mktemp -d)

# Cleanup on exit
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        log_verbose "Cleaned up temporary directory: $TEMP_DIR"
    fi
}
trap cleanup EXIT

# Help message
show_help() {
    cat << EOF
${CYAN}Master Subdomain Enumeration Script${NC}
${CYAN}=====================================${NC}

Usage: $0 -d <domain> [-o output_file] [-v] [-h]

OPTIONS:
  -d, --domain DOMAIN     Target domain to enumerate (required)
  -o, --output OUTPUT     Save results to file (default: <domain>_subdomains.txt)
  -v, --verbose           Enable verbose output
  -h, --help              Show this help message

DESCRIPTION:
  This script runs all available subdomain enumeration tools:

  Scripts (16):
    • abuse_ip.sh         • anubis.sh          • bevigil.sh
    • certSpotter.sh      • chaos.sh           • commoncrawl.sh
    • crt.sh              • hackertarget.sh    • leakx.sh
    • otx.sh              • rapiddns.sh        • security_trails.sh
    • subdomain_center.sh • urlscan.sh         • virustotal.sh
    • github_subdomains.sh

  Tools (3):
    • subfinder           • sublist3r          • assetfinder

EXAMPLES:
  $0 -d example.com
  $0 -d example.com -o results.txt
  $0 -d example.com -v -o results.txt

EOF
    exit 0
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_verbose() {
    if [ $VERBOSE -eq 1 ]; then
        echo -e "${MAGENTA}[VERBOSE]${NC} $1"
    fi
}

# Progress bar
progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))

    printf "\r${CYAN}Progress: [${NC}"
    printf "%${completed}s" | tr ' ' '='
    printf "%${remaining}s" | tr ' ' '-'
    printf "${CYAN}]${NC} ${GREEN}%d%%${NC} (%d/%d)" $percentage $current $total
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            ;;
    esac
done

# Validate domain
if [ -z "$DOMAIN" ]; then
    log_error "Domain is required!"
    show_help
fi

# Set default output file if not specified
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="${DOMAIN}_subdomains.txt"
fi

# Banner
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   Master Subdomain Enumeration Script                     ║
║   Comprehensive subdomain discovery tool                  ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

log_info "Target Domain: ${GREEN}$DOMAIN${NC}"
log_info "Output File: ${GREEN}$OUTPUT_FILE${NC}"
log_info "Verbose Mode: ${GREEN}$([ $VERBOSE -eq 1 ] && echo 'Enabled' || echo 'Disabled')${NC}"
log_info "Temporary Directory: ${GREEN}$TEMP_DIR${NC}"
echo ""

# List of all scripts
SCRIPTS=(
    "abuse_ip.sh"
    "anubis.sh"
    "bevigil.sh"
    "certSpotter.sh"
    "chaos.sh"
    "commoncrawl.sh"
    "crt.sh"
    "github_subdomains.sh"
    "hackertarget.sh"
    "leakx.sh"
    "otx.sh"
    "rapiddns.sh"
    "security_trails.sh"
    "subdomain_center.sh"
    "urlscan.sh"
    "virustotal.sh"
)

# List of tools
TOOLS=(
    "subfinder"
    "sublist3r"
    "assetfinder"
)

TOTAL_SOURCES=$((${#SCRIPTS[@]} + ${#TOOLS[@]}))
CURRENT=0

log_info "Starting enumeration with ${TOTAL_SOURCES} sources..."
echo ""

# Run each script
log_info "${CYAN}Running Scripts (${#SCRIPTS[@]})...${NC}"
echo ""

for script in "${SCRIPTS[@]}"; do
    CURRENT=$((CURRENT + 1))
    script_path="${SCRIPT_DIR}/${script}"
    temp_output="${TEMP_DIR}/${script}.txt"

    if [ ! -f "$script_path" ]; then
        log_warning "Script not found: $script"
        progress_bar $CURRENT $TOTAL_SOURCES
        continue
    fi

    log_verbose "Running: $script"

    # Run script with domain as positional argument and -o flag for output
    if [ $VERBOSE -eq 1 ]; then
        bash "$script_path" "$DOMAIN" -o "$temp_output" 2>&1
    else
        bash "$script_path" "$DOMAIN" -o "$temp_output" >/dev/null 2>&1
    fi

    if [ $? -eq 0 ] && [ -s "$temp_output" ]; then
        count=$(wc -l < "$temp_output")
        log_verbose "✓ ${script}: Found ${count} subdomains"
    else
        log_verbose "✗ ${script}: No results or error"
    fi

    progress_bar $CURRENT $TOTAL_SOURCES
done

echo ""
echo ""

# Run tools
log_info "${CYAN}Running Tools (${#TOOLS[@]})...${NC}"
echo ""

# Subfinder
CURRENT=$((CURRENT + 1))
log_verbose "Running: subfinder"
temp_output="${TEMP_DIR}/subfinder.txt"

if command -v subfinder >/dev/null 2>&1; then
    if [ $VERBOSE -eq 1 ]; then
        subfinder -d "$DOMAIN" -all -recursive -o "$temp_output" 2>&1
    else
        subfinder -d "$DOMAIN" -all -recursive -o "$temp_output" >/dev/null 2>&1
    fi

    if [ $? -eq 0 ] && [ -s "$temp_output" ]; then
        count=$(wc -l < "$temp_output")
        log_verbose "✓ subfinder: Found ${count} subdomains"
    else
        log_verbose "✗ subfinder: No results or error"
    fi
else
    log_warning "subfinder not found in PATH"
fi
progress_bar $CURRENT $TOTAL_SOURCES

# Sublist3r
CURRENT=$((CURRENT + 1))
log_verbose "Running: sublist3r"
temp_output="${TEMP_DIR}/sublist3r.txt"

if command -v sublist3r >/dev/null 2>&1; then
    if [ $VERBOSE -eq 1 ]; then
        sublist3r -d "$DOMAIN" -o "$temp_output" 2>&1
    else
        sublist3r -d "$DOMAIN" -o "$temp_output" >/dev/null 2>&1
    fi

    if [ $? -eq 0 ] && [ -s "$temp_output" ]; then
        count=$(wc -l < "$temp_output")
        log_verbose "✓ sublist3r: Found ${count} subdomains"
    else
        log_verbose "✗ sublist3r: No results or error"
    fi
else
    log_warning "sublist3r not found in PATH"
fi
progress_bar $CURRENT $TOTAL_SOURCES

# Assetfinder
CURRENT=$((CURRENT + 1))
log_verbose "Running: assetfinder"
temp_output="${TEMP_DIR}/assetfinder.txt"

if command -v assetfinder >/dev/null 2>&1; then
    if [ $VERBOSE -eq 1 ]; then
        assetfinder --subs-only "$DOMAIN" | tee "$temp_output"
    else
        assetfinder --subs-only "$DOMAIN" > "$temp_output" 2>/dev/null
    fi

    if [ $? -eq 0 ] && [ -s "$temp_output" ]; then
        count=$(wc -l < "$temp_output")
        log_verbose "✓ assetfinder: Found ${count} subdomains"
    else
        log_verbose "✗ assetfinder: No results or error"
    fi
else
    log_warning "assetfinder not found in PATH"
fi
progress_bar $CURRENT $TOTAL_SOURCES

echo ""
echo ""

# Combine and deduplicate results
log_info "Combining and deduplicating results..."

# Merge all results
cat "$TEMP_DIR"/*.txt 2>/dev/null | \
    grep -v "^$" | \
    grep -v "^#" | \
    grep -E "^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$" | \
    sort -u > "$OUTPUT_FILE"


# Final statistics
TOTAL_UNIQUE=$(wc -l < "$OUTPUT_FILE")

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ENUMERATION COMPLETE                   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
log_success "Total unique subdomains found: ${CYAN}${TOTAL_UNIQUE}${NC}"
log_success "Results saved to: ${CYAN}${OUTPUT_FILE}${NC}"
echo ""

# Show sample results if verbose
if [ $VERBOSE -eq 1 ] && [ $TOTAL_UNIQUE -gt 0 ]; then
    log_info "Sample results (first 10):"
    echo ""
    head -10 "$OUTPUT_FILE" | while read -r line; do
        echo "  ${CYAN}→${NC} $line"
    done

    if [ $TOTAL_UNIQUE -gt 10 ]; then
        echo "  ${YELLOW}... and $((TOTAL_UNIQUE - 10)) more${NC}"
    fi
    echo ""
fi

# Show breakdown by source
if [ $VERBOSE -eq 1 ]; then
    log_info "Results breakdown by source:"
    echo ""
    for file in "$TEMP_DIR"/*.txt; do
        if [ -f "$file" ]; then
            source_name=$(basename "$file" .txt)
            count=$(wc -l < "$file" 2>/dev/null || echo 0)
            if [ $count -gt 0 ]; then
                printf "  %-25s ${GREEN}%6d${NC} subdomains\n" "$source_name:" "$count"
            fi
        fi
    done
    echo ""
fi

log_success "Enumeration completed successfully!"
log_verbose "Temporary directory will be cleaned up automatically"
echo ""
