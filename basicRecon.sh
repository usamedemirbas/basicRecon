#!/bin/bash

# Define target domain and output files
TARGET_DOMAIN=""
OUTPUT_DIR="recon_output"

while getopts "d:" opt; do
  case $opt in
    d)
      TARGET_DOMAIN="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [ -z "$TARGET_DOMAIN" ]; then
  echo "Usage: ./recon.sh -d target.com"
  exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Step 1: Linked Discovery with Gospider
###

# Step 2: Subdomain Scraping with Google and amass (passive method)
amass enum -passive -d "$TARGET_DOMAIN" -o "$OUTPUT_DIR/amass_output.txt"

# Step 3: Subdomain enumeration with amass using a specific wordlist
#gobuster dns -d "$TARGET_DOMAIN" -w ~/wordlists/n0kovo_subdomains_medium.txt -o "$OUTPUT_DIR/bruteDNS.txt"
#awk -F' ' '{print $2}' "$OUTPUT_DIR/bruteDNS.txt">"$OUTPUT_DIR/cleanDNS.txt"
amass enum -active -d "$TARGET_DOMAIN" -brute -w ~/wordlists/n0kovo_subdomains_medium.txt -o "$OUTPUT_DIR/bruteDNS.txt"

# Combine subdomains and remove duplicates
#cat "$OUTPUT_DIR/amass_output.txt" "$OUTPUT_DIR/cleanDNS.txt" | sort -u > "$OUTPUT_DIR/allsubdomains.txt"

cat allsubdomains.txt | aquatone -ports xlarge -out aqua_$1

# Step 4: Port scanning and writing to openPorts.txt
#masscan -p1-65535 -iL "$OUTPUT_DIR/allsubdomains.txt" --max-rate 1800 -oG "$OUTPUT_DIR/mass_output.log"

nmap -p- -iL "$OUTPUT_DIR/allsubdomains.txt" -oG "$OUTPUT_DIR/nmap_output.txt"
awk '/Ports:/{print $2}' "$OUTPUT_DIR/nmap_output.txt" > "$OUTPUT_DIR/openPorts.txt"


# Step 5: Check live hosts with httpx
httpx -l "$OUTPUT_DIR/allsubdomains.txt" -o "$OUTPUT_DIR/liveSubdomains.txt" -threads 200 -status-code -follow-redirects

#cat liveSubdomains.txt|aquatone -t 10 -out "$OUTPUT_DIR/aquatone"
####
# Linked discover with gospider
##gospider -S liveSubdomains.txt -o "$OUTPUT_DIR/gospider_output.txt"

# Step 6: Directory search with Dirsearch
#for domain in $(cat "$OUTPUT_DIR/liveSubdomains.txt"); do
#  dirsearch -u "$domain" -w ~/tools/dirsearch/db/dicc.txt -o "$OUTPUT_DIR/dirsearch_output/$domain"
#done

# Step 7: Find sub-subdomains with Sublist3r
########################

# Step 8: Gather URLs and endpoints
#cat "$OUTPUT_DIR/liveSubdomains.txt" | waybackurls > "$OUTPUT_DIR/waybackurls.txt"
#cat "$OUTPUT_DIR/waybackurls.txt" | gf ssrf > "$OUTPUT_DIR/ssrf.txt"
#cat "$OUTPUT_DIR/waybackurls.txt" | gf sqli > "$OUTPUT_DIR/sqli.txt"
#cat "$OUTPUT_DIR/waybackurls.txt" | gf open-redirect > "$OUTPUT_DIR/openredirect.txt"
#cat "$OUTPUT_DIR/waybackurls.txt" | grep -E '\.php|\.jsp|\.asp|\.aspx' > "$OUTPUT_DIR/phpUrls.txt"

# Step 9: Extract JS files, URLs, and endpoints
#mkdir -p "$OUTPUT_DIR/js_output"
#for domain in $(cat "$OUTPUT_DIR/liveSubdomains.txt"); do
#  aquatone-takeover -d "$domain" -out "$OUTPUT_DIR/js_output/$domain"
#done

# Additional actions, e.g., analyzing JS files for API keys and more

echo "Reconnaissance completed. Output is stored in $OUTPUT_DIR directory."
