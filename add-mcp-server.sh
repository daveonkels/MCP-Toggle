#!/bin/bash

# Add MCP Server Script
# Allows adding new MCP servers with option to start inactive

# Set PATH to include homebrew and common locations
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Set HOME if not set (fallback to root if somehow not available)
: ${HOME:=~}

# Configuration files
CONFIG_FILE="$HOME/.mcp-toggle-config.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Unicode symbols
CHECK_MARK='✓'
CROSS_MARK='✗'
ARROW='→'

# Function to find Claude configuration file
find_claude_config() {
    # Check for configuration files in order of precedence:
    # 1. Local .claude.json in current directory
    # 2. Local .mcp.json in current directory
    # 3. User ~/.claude.json (fallback)

    if [ -f ".claude.json" ]; then
        echo ".claude.json"
    elif [ -f ".mcp.json" ]; then
        echo ".mcp.json"
    elif [ -f "$HOME/.claude.json" ]; then
        echo "$HOME/.claude.json"
    else
        echo ""
    fi
}

# Function to check if server exists
server_exists() {
    local server_name="$1"
    local claude_config_file=$(find_claude_config)

    # Check active servers
    if [ -n "$claude_config_file" ] && [ -f "$claude_config_file" ]; then
        if python3 -c "
import json, sys
try:
    with open('$claude_config_file', 'r') as f:
        config = json.load(f)
    servers = config.get('mcpServers', {})
    sys.exit(0 if '$server_name' in servers else 1)
except:
    sys.exit(1)
"; then
            return 0
        fi
    fi

    # Check disabled servers
    if [ -f "$CONFIG_FILE" ]; then
        if python3 -c "
import json, sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)
    sys.exit(0 if '$server_name' in config else 1)
except:
    sys.exit(1)
"; then
            return 0
        fi
    fi

    return 1
}

# Function to add server to disabled config
add_to_disabled() {
    local server_name="$1"
    local command="$2"
    local args="$3"
    local env_vars="$4"
    local claude_config_file="$5"

    # Create server configuration
    local server_config
    if [ -n "$env_vars" ]; then
        server_config=$(python3 -c "
import json, sys
config = {
    'type': 'stdio',
    'command': '$command',
    'args': json.loads('$args'),
    'env': json.loads('$env_vars')
}
print(json.dumps(config))
")
    else
        server_config=$(python3 -c "
import json, sys
config = {
    'type': 'stdio',
    'command': '$command',
    'args': json.loads('$args')
}
print(json.dumps(config))
")
    fi

    # Add to disabled servers config
    python3 -c "
import json
import os
from datetime import datetime, timezone

config_file = '$CONFIG_FILE'
server_name = '$server_name'
server_config = json.loads('$server_config')
source_file = '$claude_config_file'

# Load existing disabled config or create new
if os.path.exists(config_file):
    with open(config_file, 'r') as f:
        disabled_config = json.load(f)
else:
    disabled_config = {}

# Add server to disabled config
disabled_config[server_name] = {
    'config': server_config,
    'disabled_at': datetime.now(timezone.utc).isoformat(),
    'source_file': source_file
}

# Save updated config
with open(config_file, 'w') as f:
    json.dump(disabled_config, f, indent=2)
"
}

# Function to add server to active config
add_to_active() {
    local server_name="$1"
    local command="$2"
    local args="$3"
    local env_vars="$4"
    local claude_config_file="$5"

    # Create server configuration
    local server_config
    if [ -n "$env_vars" ]; then
        server_config=$(python3 -c "
import json, sys
config = {
    'type': 'stdio',
    'command': '$command',
    'args': json.loads('$args'),
    'env': json.loads('$env_vars')
}
print(json.dumps(config))
")
    else
        server_config=$(python3 -c "
import json, sys
config = {
    'type': 'stdio',
    'command': '$command',
    'args': json.loads('$args')
}
print(json.dumps(config))
")
    fi

    # Add to active Claude config
    python3 -c "
import json
import os

config_file = '$claude_config_file'
server_name = '$server_name'
server_config = json.loads('$server_config')

# Load existing config or create new
if os.path.exists(config_file):
    with open(config_file, 'r') as f:
        claude_config = json.load(f)
else:
    claude_config = {}

# Ensure mcpServers section exists
if 'mcpServers' not in claude_config:
    claude_config['mcpServers'] = {}

# Add server
claude_config['mcpServers'][server_name] = server_config

# Save updated config
with open(config_file, 'w') as f:
    json.dump(claude_config, f, indent=2)
"
}

# Function to validate command exists
validate_command() {
    local command="$1"

    if command -v "$command" > /dev/null 2>&1; then
        return 0
    else
        echo -e "${YELLOW}⚠️  Warning: Command '$command' not found in PATH${NC}"
        echo -e "${CYAN}This is okay if it's an absolute path or will be available when Claude runs${NC}"
        return 0
    fi
}

# Main function
main() {
    echo -e "${BOLD}${BLUE}Add New MCP Server${NC}"
    echo "=" * 50

    # Find Claude config file
    local claude_config_file=$(find_claude_config)
    if [ -z "$claude_config_file" ]; then
        echo -e "${RED}${CROSS_MARK} No Claude configuration file found${NC}"
        echo -e "${CYAN}Expected files: .claude.json, .mcp.json, or ~/.claude.json${NC}"
        exit 1
    fi

    echo -e "${GREEN}Using configuration file: $claude_config_file${NC}"
    echo

    # Get server name
    while true; do
        read -p "Enter server name (e.g., 'my-server'): " server_name

        if [ -z "$server_name" ]; then
            echo -e "${RED}Server name cannot be empty${NC}"
            continue
        fi

        # Check if server already exists
        if server_exists "$server_name"; then
            echo -e "${RED}${CROSS_MARK} Server '$server_name' already exists${NC}"
            continue
        fi

        break
    done

    # Get command
    while true; do
        read -p "Enter command (e.g., 'npx', 'python3', '/path/to/executable'): " command

        if [ -z "$command" ]; then
            echo -e "${RED}Command cannot be empty${NC}"
            continue
        fi

        validate_command "$command"
        break
    done

    # Get arguments
    echo -e "${CYAN}Enter command arguments (one per line, press Enter on empty line to finish):${NC}"
    args_array=()
    while true; do
        read -p "Arg ${#args_array[@]}: " arg

        if [ -z "$arg" ]; then
            break
        fi

        args_array+=("$arg")
    done

    # Convert args to JSON
    args_json=$(python3 -c "
import json, sys
args = [$(printf '\"%s\",' "${args_array[@]}" | sed 's/,$//')]
print(json.dumps(args))
")

    # Ask about environment variables
    env_vars=""
    read -p "Does this server need environment variables? (y/n): " needs_env

    if [[ "$needs_env" =~ ^[Yy] ]]; then
        echo -e "${CYAN}Enter environment variables (KEY=value format, one per line, press Enter on empty line to finish):${NC}"
        env_dict="{"
        first=true

        while true; do
            read -p "Env var: " env_var

            if [ -z "$env_var" ]; then
                break
            fi

            if [[ "$env_var" =~ ^[A-Za-z_][A-Za-z0-9_]*=.* ]]; then
                key=$(echo "$env_var" | cut -d'=' -f1)
                value=$(echo "$env_var" | cut -d'=' -f2-)

                if [ "$first" = true ]; then
                    first=false
                else
                    env_dict="$env_dict,"
                fi

                env_dict="$env_dict\"$key\":\"$value\""
            else
                echo -e "${RED}Invalid format. Use KEY=value${NC}"
            fi
        done

        env_dict="$env_dict}"

        if [ "$env_dict" != "{}" ]; then
            env_vars="$env_dict"
        fi
    fi

    # Ask about initial state
    echo
    read -p "Start server active? (y/n, default: n): " start_active

    echo
    echo -e "${BOLD}Server Configuration:${NC}"
    echo -e "${CYAN}Name:${NC} $server_name"
    echo -e "${CYAN}Command:${NC} $command"
    echo -e "${CYAN}Args:${NC} $args_json"
    if [ -n "$env_vars" ]; then
        echo -e "${CYAN}Environment:${NC} $env_vars"
    fi
    echo -e "${CYAN}Initial State:${NC} $([ "$start_active" = "y" ] && echo "Active" || echo "Inactive")"
    echo

    read -p "Add this server? (y/n): " confirm

    if [[ ! "$confirm" =~ ^[Yy] ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        exit 0
    fi

    # Add the server
    if [[ "$start_active" =~ ^[Yy] ]]; then
        add_to_active "$server_name" "$command" "$args_json" "$env_vars" "$claude_config_file"
        echo -e "${GREEN}${CHECK_MARK} Server '$server_name' added and activated${NC}"
        echo -e "${YELLOW}Restart Claude Code for changes to take effect${NC}"
    else
        add_to_disabled "$server_name" "$command" "$args_json" "$env_vars" "$claude_config_file"
        echo -e "${GREEN}${CHECK_MARK} Server '$server_name' added to inactive servers${NC}"
        echo -e "${CYAN}Use './toggle-mcp-server.sh enable $server_name' to activate when ready${NC}"
    fi
}

# Show help
show_help() {
    echo -e "${BOLD}Add MCP Server Script${NC}"
    echo
    echo "This script helps you add new MCP servers to your Claude configuration."
    echo
    echo -e "${BOLD}Usage:${NC}"
    echo "  $0                    # Interactive mode"
    echo "  $0 --help            # Show this help"
    echo
    echo -e "${BOLD}Features:${NC}"
    echo "• Interactive prompts for server configuration"
    echo "• Validates server names don't conflict"
    echo "• Supports environment variables"
    echo "• Option to start active or inactive"
    echo "• Auto-detects correct Claude config file"
    echo
    echo -e "${BOLD}Examples:${NC}"
    echo "• Add a Node.js MCP server"
    echo "• Add a Python MCP server with environment variables"
    echo "• Add a Docker-based MCP server"
}

# Check arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# Run main function
main