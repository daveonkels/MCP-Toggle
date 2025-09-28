#!/bin/bash

# FUNCTIONALITY:
# Master MCP controller for Raycast that provides a unified interface
# to the main toggle-mcp-server.sh script. Offers all major operations
# through a single Raycast command with action selection.
# 
# Features:
# - Status display with improved formatting
# - Individual server enable/disable (requires manual server name input)
# - Bulk operations (enable-all/disable-all)
# - Error handling and user guidance
# - Colored output for better readability

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title MCP Master Controller
# @raycast.mode fullOutput
# @raycast.packageName MCP Tools

# Optional parameters:
# @raycast.icon 🔌
# @raycast.argument1 { "type": "dropdown", "placeholder": "Action", "data": [{"title": "Status", "value": "status"}, {"title": "Disable Server", "value": "disable"}, {"title": "Enable Server", "value": "enable"}, {"title": "Disable ALL", "value": "disable-all"}, {"title": "Enable ALL", "value": "enable-all"}, {"title": "List Disabled", "value": "list-disabled"}] }
# @raycast.argument2 { "type": "text", "placeholder": "Server Name (required for enable/disable)", "optional": true }

# Documentation:
# @raycast.description Master MCP server controller for Claude Code - manage individual servers or all at once
# @raycast.author your-username

# Set explicit paths and environment
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
: ${HOME:=~}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOGGLE_SCRIPT="$SCRIPT_DIR/toggle-mcp-server.sh"
ACTION="$1"
SERVER="$2"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if main script exists
if [ ! -f "$TOGGLE_SCRIPT" ]; then
    echo -e "${RED}Error: Main script not found at $TOGGLE_SCRIPT${NC}"
    exit 1
fi

case "$ACTION" in
    status)
        echo -e "${BLUE}📊 MCP Server Status${NC}"
        echo "=================================================="
        $TOGGLE_SCRIPT status
        ;;
    
    disable)
        if [ -z "$SERVER" ]; then
            echo -e "${YELLOW}⚠️  Please specify a server name to disable${NC}"
            echo ""
            echo -e "${BLUE}Available servers:${NC}"
            $TOGGLE_SCRIPT status | grep -A 100 "Active MCP Servers" | grep ":" | grep -v "===" | sed 's/^/  • /' | cut -d: -f1 | sed 's/  • /  • /'
            echo ""
            echo -e "${BLUE}💡 Usage: Select 'Disable Server' and enter server name${NC}"
        else
            echo -e "${YELLOW}🔌 Disabling MCP Server: $SERVER${NC}"
            $TOGGLE_SCRIPT disable "$SERVER"
        fi
        ;;
    
    enable)
        if [ -z "$SERVER" ]; then
            echo -e "${YELLOW}⚠️  Please specify a server name to enable${NC}"
            echo ""
            echo -e "${BLUE}Available disabled servers:${NC}"
            $TOGGLE_SCRIPT list-disabled | grep -v "===" | sed 's/^/  • /'
            echo ""
            echo -e "${BLUE}💡 Usage: Select 'Enable Server' and enter server name${NC}"
        else
            echo -e "${GREEN}🔌 Enabling MCP Server: $SERVER${NC}"
            $TOGGLE_SCRIPT enable "$SERVER"
        fi
        ;;
    
    disable-all)
        echo -e "${YELLOW}⚠️  Disabling ALL MCP Servers${NC}"
        echo -e "${RED}This will disable ALL active MCP servers!${NC}"
        echo ""
        $TOGGLE_SCRIPT disable-all
        ;;
    
    enable-all)
        echo -e "${GREEN}🔌 Enabling ALL Disabled MCP Servers${NC}"
        echo ""
        $TOGGLE_SCRIPT enable-all
        ;;
    
    list-disabled)
        echo -e "${BLUE}⏸️  Disabled MCP Servers${NC}"
        echo "=================================================="
        $TOGGLE_SCRIPT list-disabled
        ;;
    
    *)
        echo -e "${RED}❌ Invalid action: $ACTION${NC}"
        echo ""
        echo -e "${BLUE}Available actions:${NC}"
        echo "  • status      - Show all servers"
        echo "  • disable     - Disable a server"
        echo "  • enable      - Enable a server"
        echo "  • disable-all - Disable all servers"
        echo "  • enable-all  - Enable all disabled servers"
        echo "  • list-disabled - Show disabled servers only"
        exit 1
        ;;
esac