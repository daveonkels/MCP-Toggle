#!/usr/bin/env python3

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Enable MCP Server
# @raycast.mode fullOutput
# @raycast.packageName MCP Tools

# Optional parameters:
# @raycast.icon ✅
# @raycast.argument1 { "type": "dropdown", "placeholder": "Server to Enable", "data": [{"title": "apple-mcp", "value": "apple-mcp"}, {"title": "apple-reminders", "value": "apple-reminders"}, {"title": "context7", "value": "context7"}, {"title": "desktop-commander", "value": "desktop-commander"}, {"title": "flights", "value": "flights"}, {"title": "google-maps", "value": "google-maps"}, {"title": "hass-mcp", "value": "hass-mcp"}, {"title": "iterm-mcp", "value": "iterm-mcp"}, {"title": "mcp-obsidian", "value": "mcp-obsidian"}, {"title": "mcp-reddit-companion", "value": "mcp-reddit-companion"}, {"title": "notion", "value": "notion"}, {"title": "peekaboo", "value": "peekaboo"}, {"title": "youtube", "value": "youtube"}] }

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
    
    print(f"🔌 Enabling MCP Server: {server_name}")
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
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()
