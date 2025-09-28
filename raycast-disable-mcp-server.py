#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Disable MCP Server
# @raycast.mode fullOutput
# @raycast.packageName MCP Tools

# Optional parameters:
# @raycast.icon ❌
# @raycast.argument1 { "type": "dropdown", "placeholder": "Server to Disable", "data": [{"title": "browsermcp", "value": "browsermcp"}, {"title": "fastmail", "value": "fastmail"}, {"title": "paperless", "value": "paperless"}] }

# Documentation:
# @raycast.description Disable an active MCP server
# @raycast.author your-username

import sys
import subprocess

def main():
    if len(sys.argv) < 2:
        print("❌ No server specified")
        return
    
    server_name = sys.argv[1]
    
    if server_name == "none":
        print("⚠️  No active servers available to disable")
        return
    
    print(f"🔌 Disabling MCP Server: {server_name}")
    print("=" * 50)
    
    try:
        result = subprocess.run([
            os.path.join(SCRIPT_DIR, "toggle-mcp-server.sh"), 
            "disable", 
            server_name
        ], capture_output=True, text=True)
        
        print(result.stdout)
        if result.stderr:
            print(result.stderr)
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
