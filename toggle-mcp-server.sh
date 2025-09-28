#!/bin/bash

# MCP Server Toggle Script for Claude Code
# 
# FUNCTIONALITY:
# This is the main script that manages MCP servers for Claude Code.
# It allows you to enable/disable individual servers or all servers at once
# while preserving their COMPLETE configuration for easy re-enabling later.
# 
# Features:
# - Save FULL server configurations when disabling (including env vars, type, etc.)
# - Beautiful colored status display with Unicode symbols and borders
# - Enable/disable individual servers or all servers at once
# - Command truncation for better readability
# - Formatted timestamps for disabled servers
# - Detects and uses the correct configuration file based on current directory
# 
# Allows easy enable/disable of MCP servers without losing configuration

# Set PATH to include homebrew and common locations
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Set HOME if not set (fallback to root if somehow not available)
: ${HOME:=~}

# Ensure Claude config directory is accessible
export CLAUDE_CONFIG_DIR="$HOME/.claude"

CONFIG_FILE="$HOME/.mcp-toggle-config.json"
CLAUDE_COMMAND="/opt/homebrew/bin/claude"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Unicode symbols
CHECK_MARK='✓'
CROSS_MARK='✗'
BULLET='•'
ARROW='→'
CLOCK='🕐'

# Initialize config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo "{}" > "$CONFIG_FILE"
fi

# Function to find the active Claude configuration file
# Claude Code uses a hierarchy:
# 1. Local .claude.json in current project directory
# 2. Project .mcp.json in current project directory  
# 3. User ~/.claude.json (fallback)
find_claude_config() {
    local current_dir="${1:-$(pwd)}"
    
    # Check for local .claude.json in current directory or parent directories
    local check_dir="$current_dir"
    while [ "$check_dir" != "/" ]; do
        if [ -f "$check_dir/.claude.json" ] && [ "$check_dir" != "$HOME" ]; then
            echo "$check_dir/.claude.json"
            return 0
        fi
        check_dir=$(dirname "$check_dir")
    done
    
    # Check for .mcp.json in current directory or parent directories
    check_dir="$current_dir"
    while [ "$check_dir" != "/" ]; do
        if [ -f "$check_dir/.mcp.json" ]; then
            echo "$check_dir/.mcp.json"
            return 0
        fi
        check_dir=$(dirname "$check_dir")
    done
    
    # Default to user config
    echo "$HOME/.claude.json"
}

# Function to get all active servers from all mcpServers sections
get_all_active_servers() {
    local config_file="${1:-$(find_claude_config)}"

    if [ ! -f "$config_file" ]; then
        echo "{}"
        return 1
    fi

    # Get all mcpServers from all sections (global and session-specific)
    python3 -c "
import json
try:
    with open('$config_file', 'r') as f:
        config = json.load(f)

    all_servers = {}

    # Add global mcpServers (at root level)
    if 'mcpServers' in config and isinstance(config['mcpServers'], dict):
        all_servers.update(config['mcpServers'])

    # Add session-specific mcpServers (in conversation contexts)
    def find_mcp_servers(obj, path=''):
        if isinstance(obj, dict):
            for key, value in obj.items():
                current_path = f'{path}.{key}' if path else key
                if key == 'mcpServers' and isinstance(value, dict) and value:
                    # Merge session servers, with newer sessions taking precedence
                    all_servers.update(value)
                elif isinstance(value, (dict, list)):
                    find_mcp_servers(value, current_path)
        elif isinstance(obj, list):
            for i, item in enumerate(obj):
                find_mcp_servers(item, f'{path}[{i}]')

    find_mcp_servers(config)
    print(json.dumps(all_servers))
except Exception as e:
    print('{}')
"
}

# Function to save COMPLETE server configuration
save_server_config() {
    local server_name="$1"
    local config_file="${2:-$(find_claude_config)}"
    
    # Get FULL server config directly from Claude config file
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: Claude config file not found at $config_file${NC}"
        return 1
    fi
    
    # Get server config from any mcpServers section
    local server_json=$(python3 -c "
import json
import sys
try:
    with open('$config_file', 'r') as f:
        config = json.load(f)

    found_server = None

    # Check global mcpServers first
    if 'mcpServers' in config and isinstance(config['mcpServers'], dict):
        if '$server_name' in config['mcpServers']:
            found_server = config['mcpServers']['$server_name']

    # Search session-specific mcpServers if not found
    if not found_server:
        def find_server_in_sessions(obj):
            if isinstance(obj, dict):
                for key, value in obj.items():
                    if key == 'mcpServers' and isinstance(value, dict):
                        if '$server_name' in value:
                            return value['$server_name']
                    elif isinstance(value, (dict, list)):
                        result = find_server_in_sessions(value)
                        if result:
                            return result
            elif isinstance(obj, list):
                for item in obj:
                    result = find_server_in_sessions(item)
                    if result:
                        return result
            return None

        found_server = find_server_in_sessions(config)

    if found_server:
        print(json.dumps(found_server))
    else:
        sys.exit(1)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null)
    
    if [ -z "$server_json" ]; then
        echo -e "${RED}Error: Server '$server_name' not found in configuration${NC}"
        return 1
    fi
    
    # Save COMPLETE config using python (preserves all fields)
    python3 -c "
import json
import datetime

# Load existing saved configs
with open('$CONFIG_FILE', 'r') as f:
    saved_configs = json.load(f)

# Parse the server configuration
server_config = json.loads('''$server_json''')

# Save the complete configuration with metadata
saved_configs['$server_name'] = {
    'config': server_config,
    'disabled_at': datetime.datetime.now().isoformat(),
    'source_file': '$config_file'
}

# Write back
with open('$CONFIG_FILE', 'w') as f:
    json.dump(saved_configs, f, indent=2)
"
    
    echo -e "${GREEN}✓ Saved complete configuration for '$server_name'${NC}"
    return 0
}

# Function to disable a server
disable_server() {
    local server_name="$1"
    local config_file="$(find_claude_config)"
    
    echo -e "${YELLOW}Disabling MCP server: $server_name${NC}"
    echo -e "${DIM}Using config: $config_file${NC}"
    
    # First save the complete configuration
    if save_server_config "$server_name" "$config_file"; then
        # Now remove the server from Claude config
        python3 -c "
import json
with open('$config_file', 'r') as f:
    config = json.load(f)
if 'mcpServers' in config and '$server_name' in config['mcpServers']:
    del config['mcpServers']['$server_name']
    with open('$config_file', 'w') as f:
        json.dump(config, f, indent=2)
    print('Success')
else:
    print('Server not found')
    exit(1)
" 2>/dev/null
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✓ Server '$server_name' has been disabled${NC}"
            echo -e "${BLUE}To re-enable, run: $0 enable $server_name${NC}"
            echo -e "${YELLOW}Note: Restart Claude Code for changes to take effect${NC}"
        else
            echo -e "${RED}Error removing server from Claude Code${NC}"
            return 1
        fi
    else
        return 1
    fi
}

# Function to enable a server with COMPLETE configuration
enable_server() {
    local server_name="$1"
    local target_config="${2:-$(find_claude_config)}"
    
    echo -e "${YELLOW}Enabling MCP server: $server_name${NC}"
    echo -e "${DIM}Target config: $target_config${NC}"
    
    # Check if we have saved config for this server
    local saved_data=$(python3 -c "
import json
try:
    with open('$CONFIG_FILE', 'r') as f:
        saved_configs = json.load(f)
    if '$server_name' in saved_configs:
        import sys
        json.dump(saved_configs['$server_name'], sys.stdout)
    else:
        exit(1)
except:
    exit(1)
" 2>/dev/null)
    
    if [ -z "$saved_data" ]; then
        echo -e "${RED}Error: No saved configuration for '$server_name'${NC}"
        echo -e "${BLUE}Available disabled servers:${NC}"
        list_disabled
        return 1
    fi
    
    # Check for environment variables and apply them
    local env_file="$HOME/.mcp-env.json"
    local has_env_vars="false"
    
    if [ -f "$env_file" ]; then
        has_env_vars=$(python3 -c "
import json
try:
    with open('$env_file', 'r') as f:
        env_config = json.load(f)
    if '$server_name' in env_config:
        print('true')
    else:
        print('false')
except:
    print('false')
" 2>/dev/null)
    fi
    
    # Re-add the COMPLETE server configuration to Claude config
    echo "Re-adding server '$server_name' to Claude configuration"
    
    python3 -c "
import json
import sys
import os

# Load saved data
saved_data = json.loads('''$saved_data''')
server_config = saved_data['config']

# Check for environment variables
env_file = '$env_file'
if os.path.exists(env_file) and '$has_env_vars' == 'true':
    with open(env_file, 'r') as f:
        env_config = json.load(f)
    if '$server_name' in env_config:
        server_config['env'] = env_config['$server_name']
        print(f'Applied environment variables for $server_name', file=sys.stderr)

# Load target config file
try:
    with open('$target_config', 'r') as f:
        config = json.load(f)
except FileNotFoundError:
    config = {}

# Ensure mcpServers exists
if 'mcpServers' not in config:
    config['mcpServers'] = {}

# Restore the COMPLETE server configuration
config['mcpServers']['$server_name'] = server_config

# Write back
with open('$target_config', 'w') as f:
    json.dump(config, f, indent=2)
print('Success')
" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        # Remove from disabled config
        python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)
if '$server_name' in config:
    del config['$server_name']
with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)
"
        
        echo -e "${GREEN}✓ Server '$server_name' has been enabled${NC}"
        
        # Special message for servers that need environment variables
        if [ "$server_name" = "hass-mcp" ] && [ "$has_env_vars" != "true" ]; then
            echo -e "${YELLOW}⚠️  hass-mcp requires environment variables to be configured${NC}"
            echo -e "${BLUE}Run this command to set them up:${NC}"
            echo -e "${BOLD}  ./setup-mcp-env.sh setup hass-mcp${NC}"
        fi
        
        echo -e "${YELLOW}Note: Restart Claude Code for changes to take effect${NC}"
    else
        echo -e "${RED}Error adding server to Claude Code${NC}"
        return 1
    fi
}

# Function to show status of all servers (checking all config files)
show_status() {
    local divider="$(printf '%.0s─' {1..60})"
    local current_config="$(find_claude_config)"
    
    echo -e "${BOLD}${CYAN}┌${divider}┐${NC}"
    echo -e "${BOLD}${CYAN}│$(printf '%*s' $(((60-20)/2)) '')${GREEN}${CHECK_MARK} Active MCP Servers${CYAN}$(printf '%*s' $(((60-20)/2)) '')│${NC}"
    echo -e "${BOLD}${CYAN}└${divider}┘${NC}"
    echo ""
    echo -e "${DIM}Active config: $current_config${NC}"
    echo ""
    
    if [ -f "$current_config" ]; then
        # Get all active servers from all sections
        local all_servers_json=$(get_all_active_servers "$current_config")
        local active_servers=$(python3 -c "
import json
try:
    servers = json.loads('$all_servers_json')
    if servers:
        for name, server in servers.items():
            # Build display command
            if 'command' in server:
                cmd_parts = [server['command']]
                if 'args' in server:
                    cmd_parts.extend(server['args'])
                command = ' '.join(cmd_parts).strip()
            else:
                command = 'Unknown command'

            # Add env var indicator
            env_indicator = ' [env]' if 'env' in server else ''

            # Truncate long commands for display
            display_cmd = command if len(command) <= 45 else command[:42] + '...'
            print(f'{name}|{display_cmd}{env_indicator}')
    else:
        print('NONE')
except Exception as e:
    print(f'ERROR|{e}')
" 2>/dev/null)
        
        if [ "$active_servers" = "NONE" ]; then
            echo -e "  ${DIM}${BULLET} No active MCP servers configured${NC}"
        elif [[ "$active_servers" == ERROR* ]]; then
            echo -e "  ${RED}${CROSS_MARK} Error reading configuration${NC}"
            echo -e "  ${DIM}${active_servers#ERROR|}${NC}"
        else
            echo "$active_servers" | while IFS='|' read -r name command; do
                if [ -n "$name" ]; then
                    echo -e "  ${GREEN}${CHECK_MARK} ${BOLD}$name${NC}"
                    echo -e "    ${CYAN}${ARROW}${NC} ${DIM}$command${NC}"
                fi
            done
        fi
    else
        echo -e "  ${RED}${CROSS_MARK} Configuration file not found at $current_config${NC}"
    fi
    
    echo ""
    echo -e "${BOLD}${MAGENTA}┌${divider}┐${NC}"
    echo -e "${BOLD}${MAGENTA}│$(printf '%*s' $(((60-21)/2)) '')${YELLOW}${CLOCK} Disabled MCP Servers${MAGENTA}$(printf '%*s' $(((60-21)/2)) '')│${NC}"
    echo -e "${BOLD}${MAGENTA}└${divider}┘${NC}"
    echo ""
    list_disabled
}

# Function to disable all servers
disable_all_servers() {
    local config_file="$(find_claude_config)"
    echo -e "${YELLOW}Disabling ALL MCP servers...${NC}"
    echo -e "${DIM}Using config: $config_file${NC}"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: Config file not found at $config_file${NC}"
        return 1
    fi
    
    # Get list of all active servers
    local active_servers=$(python3 -c "
import json
try:
    with open('$config_file', 'r') as f:
        config = json.load(f)
    if 'mcpServers' in config and config['mcpServers']:
        for name in config['mcpServers'].keys():
            print(name)
except:
    pass
" 2>/dev/null)
    
    if [ -z "$active_servers" ]; then
        echo "No active servers to disable"
        return 0
    fi
    
    local count=0
    local failed=0
    
    echo "$active_servers" | while read -r server_name; do
        if [ -n "$server_name" ]; then
            echo -e "${BLUE}Disabling: $server_name${NC}"
            if save_server_config "$server_name" "$config_file"; then
                count=$((count + 1))
            else
                failed=$((failed + 1))
            fi
        fi
    done
    
    # Remove all servers from Claude config in one operation
    python3 -c "
import json
with open('$config_file', 'r') as f:
    config = json.load(f)
config['mcpServers'] = {}
with open('$config_file', 'w') as f:
    json.dump(config, f, indent=2)
print('Success')
" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ All MCP servers have been disabled${NC}"
        echo -e "${BLUE}To re-enable all servers, run: $0 enable-all${NC}"
        echo -e "${YELLOW}Note: Restart Claude Code for changes to take effect${NC}"
    else
        echo -e "${RED}Error clearing MCP servers from configuration${NC}"
        return 1
    fi
}

# Function to enable all disabled servers
enable_all_servers() {
    local target_config="${1:-$(find_claude_config)}"
    echo -e "${YELLOW}Enabling ALL disabled MCP servers...${NC}"
    echo -e "${DIM}Target config: $target_config${NC}"
    
    # Get list of all disabled servers
    local disabled_servers=$(python3 -c "
import json
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
        for name in config.keys():
            print(name)
except:
    pass
" 2>/dev/null)
    
    if [ -z "$disabled_servers" ]; then
        echo "No disabled servers to enable"
        return 0
    fi
    
    local count=0
    local failed=0
    
    echo "$disabled_servers" | while read -r server_name; do
        if [ -n "$server_name" ]; then
            echo -e "${BLUE}Enabling: $server_name${NC}"
            if enable_server "$server_name" "$target_config" >/dev/null 2>&1; then
                echo -e "${GREEN}  ✓ $server_name enabled${NC}"
                count=$((count + 1))
            else
                echo -e "${RED}  ✗ Failed to enable $server_name${NC}"
                failed=$((failed + 1))
            fi
        fi
    done
    
    echo -e "${GREEN}✓ Finished enabling disabled servers${NC}"
    echo -e "${YELLOW}Note: Restart Claude Code for changes to take effect${NC}"
}

# Function to list disabled servers with full details
list_disabled() {
    local disabled_data=$(python3 -c "
import json
try:
    with open('$CONFIG_FILE', 'r') as f:
        saved_configs = json.load(f)
    for name, data in saved_configs.items():
        config = data.get('config', {})
        disabled_at = data.get('disabled_at', 'unknown')
        source = data.get('source_file', 'unknown')
        
        # Build command display
        if 'command' in config:
            cmd_parts = [config['command']]
            if 'args' in config:
                cmd_parts.extend(config['args'])
            cmd = ' '.join(cmd_parts)
        else:
            cmd = 'unknown'
        
        # Add env indicator
        has_env = 'env' in config
        
        # Truncate for display
        display_cmd = cmd if len(cmd) <= 45 else cmd[:42] + '...'
        if has_env:
            display_cmd += ' [env]'
        
        print(f'{name}|{display_cmd}|{disabled_at}|{source}')
except Exception as e:
    pass
" 2>/dev/null)
    
    if [ -z "$disabled_data" ]; then
        echo -e "  ${DIM}${BULLET} No disabled servers${NC}"
    else
        echo "$disabled_data" | while IFS='|' read -r name command disabled_at source; do
            if [ -n "$name" ]; then
                # Format the disabled date
                local formatted_date
                if [[ "$disabled_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2} ]]; then
                    formatted_date=$(echo "$disabled_at" | cut -c1-16 | tr 'T' ' ')
                else
                    formatted_date="$disabled_at"
                fi
                
                echo -e "  ${RED}${CROSS_MARK} ${BOLD}$name${NC}"
                echo -e "    ${CYAN}${ARROW}${NC} ${DIM}$command${NC}"
                echo -e "    ${YELLOW}${CLOCK} Disabled: ${DIM}$formatted_date${NC}"
                
                # Show source if not default
                if [ "$source" != "$HOME/.claude.json" ] && [ "$source" != "unknown" ]; then
                    echo -e "    ${BLUE}📁 From: ${DIM}$source${NC}"
                fi
            fi
        done
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
MCP Server Toggle Script for Claude Code

Usage: $0 <command> [server-name]

Commands:
    disable <server-name>   Disable an MCP server (saves complete config)
    enable <server-name>    Re-enable a previously disabled MCP server
    disable-all            Disable ALL active MCP servers
    enable-all             Re-enable ALL disabled MCP servers
    status                 Show all active and disabled servers
    list-disabled         List only disabled servers
    help                  Show this help message

Examples:
    $0 disable desktop-commander    # Disable the desktop-commander server
    $0 enable desktop-commander     # Re-enable the desktop-commander server
    $0 disable-all                  # Disable all active MCP servers
    $0 enable-all                   # Re-enable all disabled MCP servers
    $0 status                       # Show all servers and their states

Adding New Servers:
    Use add-mcp-server.sh to add new MCP servers interactively
    Run: ./add-mcp-server.sh --help for detailed input guidelines

Configuration:
    - Saved configs: $CONFIG_FILE
    - Auto-detects correct Claude config based on current directory
    - Preserves ALL server settings including environment variables
    
Note: The script will use the appropriate configuration file based on your
current directory (local .claude.json, .mcp.json, or ~/.claude.json)
EOF
}

# Main script logic
case "$1" in
    disable)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Please specify a server name${NC}"
            echo "Usage: $0 disable <server-name>"
            exit 1
        fi
        disable_server "$2"
        ;;
    enable)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Please specify a server name${NC}"
            echo "Usage: $0 enable <server-name>"
            exit 1
        fi
        enable_server "$2"
        ;;
    disable-all)
        disable_all_servers
        ;;
    enable-all)
        enable_all_servers
        ;;
    status)
        show_status
        ;;
    list-disabled)
        echo -e "${BLUE}=== Disabled MCP Servers ===${NC}"
        list_disabled
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo -e "${RED}Invalid command: $1${NC}"
        show_usage
        exit 1
        ;;
esac