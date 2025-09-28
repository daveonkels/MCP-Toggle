#!/usr/bin/env python3
"""
Generator script for raycast-enable-mcp-server.py
Creates a Raycast script with dropdown options for currently disabled MCP servers
"""

import json
import os

# Get script directory for relative paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

def get_disabled_servers():
    """Get list of currently disabled MCP servers from toggle config"""
    config_file = os.path.expanduser("~/.mcp-toggle-config.json")
    
    if not os.path.exists(config_file):
        return []
    
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
        return sorted(config.keys())
    except:
        return []

def generate_raycast_script():
    """Generate the Raycast script with current disabled servers"""
    servers = get_disabled_servers()
    
    # Create dropdown data
    if servers:
        dropdown_items = [f'{{"title": "{server}", "value": "{server}"}}' for server in servers]
        dropdown_data = f'[{", ".join(dropdown_items)}]'
    else:
        dropdown_data = '[{"title": "No disabled servers", "value": "none"}]'
    
    script_content = f'''#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Enable MCP Server
# @raycast.mode fullOutput
# @raycast.packageName MCP Tools

# Optional parameters:
# @raycast.icon ✅
# @raycast.argument1 {{ "type": "dropdown", "placeholder": "Server to Enable", "data": {dropdown_data} }}

# Documentation:
# @raycast.description Enable a disabled MCP server
# @raycast.author your-username

import sys
import subprocess

def main():
    if len(sys.argv) < 2:
        print("❌ No server specified")
        return
    
    server_name = sys.argv[1]
    
    if server_name == "none":
        print("⚠️  No disabled servers available to enable")
        return
    
    print(f"🔌 Enabling MCP Server: {{server_name}}")
    print("=" * 50)
    
    try:
        result = subprocess.run([
            os.path.join(SCRIPT_DIR, "toggle-mcp-server.sh"), 
            "enable", 
            server_name
        ], capture_output=True, text=True)
        
        print(result.stdout)
        if result.stderr:
            print(result.stderr)
            
    except Exception as e:
        print(f"❌ Error: {{e}}")

if __name__ == "__main__":
    main()
'''
    
    # Write the generated script
    output_file = os.path.join(SCRIPT_DIR, "raycast-enable-mcp-server.py")
    with open(output_file, 'w') as f:
        f.write(script_content)
    
    # Make it executable
    os.chmod(output_file, 0o755)
    
    print(f"✓ Generated {output_file}")
    print(f"  Disabled servers: {', '.join(servers) if servers else 'None'}")

if __name__ == "__main__":
    generate_raycast_script()