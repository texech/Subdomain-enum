# 🔍 Subdomain Hunting Toolkit

A comprehensive subdomain enumeration framework that aggregates results from multiple sources including custom scripts and popular reconnaissance tools.

**Created by:** Ajay Chaudhary

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [API Keys Setup](#api-keys-setup)
- [Usage](#usage)
- [Scripts Included](#scripts-included)
- [Tools Integration](#tools-integration)
- [Examples](#examples)
- [Output](#output)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Disclaimer](#disclaimer)

---

## 🎯 Overview

This toolkit provides a unified interface to run multiple subdomain enumeration techniques simultaneously. It combines 16 custom scripts with 3 popular reconnaissance tools to maximize subdomain discovery coverage.

The **master.sh** script orchestrates all enumeration sources, deduplicates results, and provides a clean output of unique subdomains for your target domain.

---

## ✨ Features

- 🚀 **19 Enumeration Sources** - Combines 16 scripts + 3 tools
- 🔄 **Automatic Deduplication** - Removes duplicate subdomains
- 📊 **Progress Tracking** - Real-time progress bar
- 📝 **Verbose Mode** - Detailed logging for debugging
- 🎨 **Colorized Output** - Easy-to-read terminal output
- 🧹 **Auto Cleanup** - Temporary files removed automatically
- 📈 **Statistics** - Breakdown of results by source

---

## 🛠️ Installation

### Prerequisites

```bash
# Basic requirements
sudo apt update
sudo apt install curl wget git jq -y

# Install Python3 (if not already installed)
sudo apt install python3 python3-pip -y
```

### Install External Tools

```bash
# Install subfinder
GO111MODULE=on go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest

# Install sublist3r
git clone https://github.com/aboul3la/Sublist3r.git
cd Sublist3r
pip3 install -r requirements.txt
sudo python3 setup.py install

# Install assetfinder
go install github.com/tomnomnom/assetfinder@latest

# Make sure Go binaries are in your PATH
export PATH=$PATH:~/go/bin
```

### Clone This Repository

```bash
git clone https://github.com/ranjaykumar84543805-cell/subdomains-enum-scripts
cd subdomains-enum-scripts/
chmod +x *.sh
```

---

## 🔑 API Keys Setup

Some scripts require API keys for enhanced functionality. **API keys are already hardcoded in the individual scripts.** You need to obtain your API keys and update them in the respective script files.

### Get Your API Keys From:

| Service | Get API Key From |
|---------|------------------|
| **BeVigil** | https://bevigil.com/osint/api-keys |
| **Chaos** | https://cloud.projectdiscovery.io/settings/api-key |
| **SecurityTrails** | https://securitytrails.com/app/account/credentials |
| **VirusTotal** | https://www.virustotal.com/gui/user/xyz/apikey |
| **LeakIX** | https://leakix.net/settings/api |
| **AlienVault OTX** | https://otx.alienvault.com/api/ |
| **GitHub** | https://github.com/settings/tokens |

### Update API Keys in Scripts

After obtaining your API keys, edit the respective script files and replace the placeholder values:

```bash
# Example: Edit bevigil.sh
nano bevigil.sh
# Find the API_KEY variable and replace with your actual key

# Example: Edit chaos.sh
nano chaos.sh
# Find the API_KEY variable and replace with your actual key
 .................  and so on

```

**Note:** Some services don't require API keys and work out of the box:
- crt.sh
- HackerTarget
- RapidDNS
- URLScan
- Anubis
- CertSpotter
- CommonCrawl
- Subdomain Center

---

## 🚀 Usage

### Basic Usage

```bash
./master.sh -d example.com
```

### Advanced Usage

```bash
# Specify custom output file
./master.sh -d example.com -o results.txt

# Enable verbose mode for detailed output
./master.sh -d example.com -v

# Combine options
./master.sh -d example.com -o my_subdomains.txt -v
```

### Help Menu

```bash
./master.sh -h
```

---

## 📦 Scripts Included

The toolkit includes 16 custom enumeration scripts:

| Script | Description | API Required |
|--------|-------------|--------------|
| `abuse_ip.sh` | AbuseIPDB subdomain lookup | No |
| `anubis.sh` | Anubis subdomain database | No |
| `bevigil.sh` | BeVigil mobile app security | Yes |
| `certSpotter.sh` | Certificate Spotter CT logs | No |
| `chaos.sh` | ProjectDiscovery Chaos dataset | Yes |
| `commoncrawl.sh` | Common Crawl archive search | No |
| `crt.sh` | Certificate Transparency logs | No |
| `github_subdomains.sh` | GitHub repository search | Yes |
| `hackertarget.sh` | HackerTarget subdomain API | No |
| `leakx.sh` | LeakIX search engine | Yes |
| `otx.sh` | AlienVault OTX threat intel | Yes |
| `rapiddns.sh` | RapidDNS subdomain lookup | No |
| `security_trails.sh` | SecurityTrails DNS intel | Yes |
| `subdomain_center.sh` | Subdomain Center database | No |
| `urlscan.sh` | URLScan.io search | No |
| `virustotal.sh` | VirusTotal subdomain lookup | Yes |

---

## 🧰 Tools Integration

The master script also integrates these popular tools:

### 1. **Subfinder**
- Fast passive subdomain enumeration
- Multiple data sources
- Recursive enumeration support

### 2. **Sublist3r**
- Python-based subdomain finder
- Multiple search engine support
- Brute-force capability

### 3. **Assetfinder**
- Quick subdomain discovery
- Lightweight and fast
- Related domains finder

---

## 💡 Examples

### Example 1: Quick Scan

```bash
./master.sh -d target.com
```

**Output:**
```
Total unique subdomains found: 1,247
Results saved to: target.com_subdomains.txt
```

### Example 2: Verbose Scan with Custom Output

```bash
./master.sh -d example.org -v -o example_results.txt
```

**Output:**
```
[INFO] Running: crt.sh
✓ crt.sh: Found 156 subdomains
[INFO] Running: virustotal.sh
✓ virustotal.sh: Found 89 subdomains
...
Total unique subdomains found: 892
Results saved to: example_results.txt
```

### Example 3: Bug Bounty Reconnaissance

```bash
#!/bin/bash
# Enumerate subdomains for multiple targets
for domain in target1.com target2.com target3.com; do
    ./master.sh -d $domain -o "${domain}_subdomains.txt" -v
done
```

---

## 📤 Output

The master script generates:

1. **Main Output File**: `<domain>_subdomains.txt`
   - Deduplicated list of subdomains
   - One subdomain per line
   - Sorted alphabetically

2. **Temporary Files**: Stored in `/tmp` during execution
   - Individual results from each source
   - Automatically cleaned up on exit

3. **Console Output**:
   - Progress bar showing enumeration status
   - Statistics and summary
   - Optional verbose logs

### Sample Output File

```
admin.example.com
api.example.com
blog.example.com
dev.example.com
mail.example.com
www.example.com
```

---

## 🔧 Troubleshooting

### Common Issues

**Issue: "Script not found" warnings**
```bash
# Solution: Make sure all scripts are executable
chmod +x *.sh
```

**Issue: "Command not found: subfinder"**
```bash
# Solution: Add Go binaries to PATH
export PATH=$PATH:~/go/bin
echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc
```

**Issue: API rate limiting**
```bash
# Solution: Make sure you've added valid API keys in the respective scripts
# Run with verbose mode to see which sources are failing
./master.sh -d example.com -v
```

**Issue: No results from API-based scripts**
```bash
# Solution: Verify your API keys are correctly configured
# Check if the API key has proper permissions
# Enable verbose mode to debug
./master.sh -d example.com -v
```

**Issue: No results returned**
```bash
# Check if domain is valid
# Verify internet connection
# Enable verbose mode to debug
./master.sh -d example.com -v
```

---

## 🤝 Contributing

Contributions are welcome! To add a new enumeration source:

1. Create a new script following the naming convention
2. Implement the `-d` and `-o` flags
3. Add the script to the `SCRIPTS` array in `master.sh`
4. Update this README
5. Submit a pull request

### Script Template

```bash
#!/bin/bash
DOMAIN=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -d) DOMAIN="$2"; shift 2 ;;
        -o) OUTPUT_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Your enumeration logic here
# Output subdomains to $OUTPUT_FILE
```

---

## ⚠️ Disclaimer

This toolkit is intended for authorized security testing and educational purposes only. Users are responsible for complying with applicable laws and regulations. Always obtain proper authorization before conducting security assessments.

**Important:**
- Only test domains you own or have explicit permission to test
- Respect API rate limits and terms of service
- Some services may log your queries
- Be mindful of network traffic generated


## 🙏 Acknowledgments

- Thanks to all the open-source projects and services integrated in this toolkit
- Community contributors who help improve subdomain enumeration techniques
- Security researchers who maintain public subdomain databases

---

## 📞 Contact

**Created by:** Ajay Chaudhary

IG :- https://www.instagram.com/ajaychaudhary_vaisnv/

For issues, suggestions, or contributions, please open an issue on the repository.

---

**Happy Hunting! 🎯**
