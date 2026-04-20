#!/bin/bash
# Script to remove iptables redirect rules and test connection
# Make sure to run this script with sudo privileges

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo ""
echo -e "${YELLOW}Removing iptables redirect rules...${NC}"
sudo iptables -t nat -D OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040 2>/dev/null
sudo iptables -t nat -D OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null
sudo iptables -t nat -D OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 5353 2>/dev/null
echo -e "${GREEN}✓  Redirect rules removed successfully${NC}"
echo ""

echo -e "${YELLOW}Testing connection to archlinux.org...${NC}"
# Test connection and hide output
if curl -s --max-time 10 https://archlinux.org > /dev/null 2>&1; then
    echo -e "${GREEN}✓  Connection test: ${BOLD}OK${NC}"
else
    echo -e "${RED}✗  Connection test: ${BOLD}NOT OK${NC}"
fi
echo ""

