#!/bin/bash

# Setup script for MCP servers that require environment variables
# This script helps configure servers like hass-mcp that need API tokens

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

ENV_FILE="$HOME/.mcp-env.json"

# Initialize env file if it doesn't exist
if [ ! -f "$ENV_FILE" ]; then
    echo "{}" > "$ENV_FILE"
    chmod 600 "$ENV_FILE"  # Restrict permissions for security
fi

# Function to setup hass-mcp
setup_hass_mcp() {
    echo -e "${BOLD}${BLUE}Setting up Home Assistant MCP Server${NC}"
    echo -e "${YELLOW}This server requires your Home Assistant URL and access token${NC}"
    echo ""
    
    # Get current values if they exist
    local current_url=$(python3 -c "
import json
try:
    with open('$ENV_FILE', 'r') as f:
        env = json.load(f)
    print(env.get('hass-mcp', {}).get('HA_URL', ''))
except:
    pass
" 2>/dev/null)
    
    local current_token=$(python3 -c "
import json
try:
    with open('$ENV_FILE', 'r') as f:
        env = json.load(f)
    token = env.get('hass-mcp', {}).get('HA_TOKEN', '')
    if token:
        # Mask the token for display
        print(token[:10] + '...' + token[-4:] if len(token) > 14 else 'SET')
except:
    pass
" 2>/dev/null)
    
    # Prompt for URL
    if [ -n "$current_url" ]; then
        echo -e "${CYAN}Current HA_URL: $current_url${NC}"
        read -p "Enter new Home Assistant URL (or press Enter to keep current): " ha_url
        if [ -z "$ha_url" ]; then
            ha_url="$current_url"
        fi
    else
        read -p "Enter your Home Assistant URL (e.g., http://homeassistant.local:8123): " ha_url
    fi
    
    # Validate URL
    if [ -z "$ha_url" ]; then
        echo -e "${RED}Error: URL cannot be empty${NC}"
        return 1
    fi
    
    # Prompt for token
    if [ -n "$current_token" ]; then
        echo -e "${CYAN}Current HA_TOKEN: $current_token${NC}"
        read -s -p "Enter new Home Assistant Long-Lived Access Token (or press Enter to keep current): " ha_token
        echo ""
        if [ -z "$ha_token" ]; then
            # Keep existing token
            ha_token="KEEP_EXISTING"
        fi
    else
        echo "To get a token: Settings → Your Profile → Long-Lived Access Tokens → Create Token"
        read -s -p "Enter your Home Assistant Long-Lived Access Token: " ha_token
        echo ""
    fi
    
    # Validate token
    if [ -z "$ha_token" ]; then
        echo -e "${RED}Error: Token cannot be empty${NC}"
        return 1
    fi
    
    # Save to env file
    python3 -c "
import json

with open('$ENV_FILE', 'r') as f:
    env_config = json.load(f)

if 'hass-mcp' not in env_config:
    env_config['hass-mcp'] = {}

env_config['hass-mcp']['HA_URL'] = '$ha_url'

# Only update token if not keeping existing
if '$ha_token' != 'KEEP_EXISTING':
    env_config['hass-mcp']['HA_TOKEN'] = '$ha_token'

with open('$ENV_FILE', 'w') as f:
    json.dump(env_config, f, indent=2)

print('✓ Environment variables saved')
"
    
    echo -e "${GREEN}✓ Home Assistant configuration saved${NC}"
    echo -e "${YELLOW}Note: These credentials will be automatically applied when you enable hass-mcp${NC}"
    
    # Now update the claude.json if hass-mcp is currently enabled
    if python3 -c "
import json
with open('$HOME/.claude.json', 'r') as f:
    config = json.load(f)
exit(0 if 'mcpServers' in config and 'hass-mcp' in config['mcpServers'] else 1)
" 2>/dev/null; then
        echo -e "${CYAN}Updating active hass-mcp configuration...${NC}"
        update_active_hass_mcp
    fi
}

# Function to update active hass-mcp with env vars
update_active_hass_mcp() {
    python3 -c "
import json

# Load env vars
with open('$ENV_FILE', 'r') as f:
    env_config = json.load(f)

if 'hass-mcp' not in env_config:
    print('No environment variables configured for hass-mcp')
    exit(1)

# Load Claude config
with open('$HOME/.claude.json', 'r') as f:
    config = json.load(f)

if 'mcpServers' in config and 'hass-mcp' in config['mcpServers']:
    # Add env field to hass-mcp
    config['mcpServers']['hass-mcp']['env'] = env_config['hass-mcp']
    
    # Save updated config
    with open('$HOME/.claude.json', 'w') as f:
        json.dump(config, f, indent=2)
    
    print('✓ Updated hass-mcp with environment variables')
else:
    print('hass-mcp is not currently enabled')
"
    
    echo -e "${YELLOW}Restart Claude Code for changes to take effect${NC}"
}

# Function to show current env configuration
show_env_status() {
    echo -e "${BOLD}${CYAN}MCP Environment Variables Configuration${NC}"
    echo "=" 
    
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${YELLOW}No environment configuration found${NC}"
        return
    fi
    
    python3 -c "
import json

try:
    with open('$ENV_FILE', 'r') as f:
        env_config = json.load(f)
    
    if not env_config:
        print('No servers configured')
    else:
        for server, vars in env_config.items():
            print(f'\\n{server}:')
            for key, value in vars.items():
                # Mask sensitive values
                if 'TOKEN' in key or 'KEY' in key or 'SECRET' in key:
                    if len(value) > 14:
                        masked = value[:6] + '...' + value[-4:]
                    else:
                        masked = 'SET'
                    print(f'  {key}: {masked}')
                else:
                    print(f'  {key}: {value}')
except Exception as e:
    print(f'Error reading config: {e}')
"
}

# Function to test hass-mcp connection
test_hass_mcp() {
    echo -e "${BOLD}${BLUE}Testing Home Assistant Connection${NC}"
    
    # Load credentials
    local ha_url=$(python3 -c "
import json
try:
    with open('$ENV_FILE', 'r') as f:
        env = json.load(f)
    print(env.get('hass-mcp', {}).get('HA_URL', ''))
except:
    pass
" 2>/dev/null)
    
    local ha_token=$(python3 -c "
import json
try:
    with open('$ENV_FILE', 'r') as f:
        env = json.load(f)
    print(env.get('hass-mcp', {}).get('HA_TOKEN', ''))
except:
    pass
" 2>/dev/null)
    
    if [ -z "$ha_url" ] || [ -z "$ha_token" ]; then
        echo -e "${RED}Error: Home Assistant credentials not configured${NC}"
        echo "Run: $0 setup hass-mcp"
        return 1
    fi
    
    echo "Testing connection to: $ha_url"
    
    # Test API connection
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $ha_token" \
        -H "Content-Type: application/json" \
        "$ha_url/api/")
    
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ Successfully connected to Home Assistant!${NC}"
        
        # Get HA info
        curl -s \
            -H "Authorization: Bearer $ha_token" \
            -H "Content-Type: application/json" \
            "$ha_url/api/config" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(f\"  Version: {data.get('version', 'unknown')}\")
    print(f\"  Location: {data.get('location_name', 'unknown')}\")
except:
    pass
" 2>/dev/null
    else
        echo -e "${RED}✗ Failed to connect (HTTP $response)${NC}"
        echo "Please check your URL and token"
    fi
}

# Show usage
show_usage() {
    cat << EOF
MCP Environment Variables Setup Script

Usage: $0 <command> [options]

Commands:
    setup hass-mcp    Configure Home Assistant credentials
    test hass-mcp     Test Home Assistant connection
    status            Show current environment configuration
    help              Show this help message

Examples:
    $0 setup hass-mcp    # Configure Home Assistant URL and token
    $0 test hass-mcp     # Test if credentials work
    $0 status            # Show all configured environment variables

Environment variables are stored in: $ENV_FILE
EOF
}

# Main script logic
case "$1" in
    setup)
        case "$2" in
            hass-mcp|hass)
                setup_hass_mcp
                ;;
            *)
                echo -e "${RED}Unknown server: $2${NC}"
                echo "Currently supported: hass-mcp"
                ;;
        esac
        ;;
    test)
        case "$2" in
            hass-mcp|hass)
                test_hass_mcp
                ;;
            *)
                echo -e "${RED}Unknown server: $2${NC}"
                ;;
        esac
        ;;
    status)
        show_env_status
        ;;
    help|--help|-h|"")
        show_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac