#!/bin/bash

# FUNCTIONALITY:
# Convenience script to refresh both dynamic Raycast dropdown scripts.
# Runs the generator scripts to update dropdown options with current
# server states (active/disabled).
# 
# Features:
# - Updates both enable and disable dropdown scripts
# - Colored output with progress indicators
# - Usage instructions for next steps
# - Can be run directly from Raycast
# 
# Script to update Raycast dropdown options with current server lists
# Run this after enabling/disabling servers to refresh the dropdown options

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Update MCP Raycast Dropdowns
# @raycast.mode fullOutput  
# @raycast.packageName MCP Tools

# Optional parameters:
# @raycast.icon 🔄

# Documentation:
# @raycast.description Update Raycast dropdown menus with current server lists
# @raycast.author your-username

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔄 Updating Raycast MCP Dropdowns${NC}"
echo "=" * 40

echo -e "${YELLOW}Generating disable server dropdown...${NC}"
python3 raycast-disable-server.py

echo -e "${YELLOW}Generating enable server dropdown...${NC}"  
python3 raycast-enable-server.py

echo ""
echo -e "${GREEN}✓ Raycast dropdowns updated successfully!${NC}"
echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo "1. Raycast will automatically detect the updated scripts"
echo "2. Use 'Enable MCP Server' to select from disabled servers"
echo "3. Use 'Disable MCP Server' to select from active servers"
echo "4. Run this update script whenever your server config changes"