# MCP Server Toggle Scripts

A comprehensive set of scripts for managing MCP (Model Context Protocol) servers in Claude Code. These scripts allow you to easily enable, disable, and manage your MCP servers without losing their configuration.

## 🚀 Features

- **Individual Server Management**: Enable/disable specific MCP servers
- **Bulk Operations**: Enable/disable ALL servers at once
- **Complete Configuration Preservation**: Saves full server objects with all parameters, environment variables, and proper JSON structure
- **Directory-Aware Configuration**: Automatically detects and uses appropriate configuration file (local `.claude.json`, `.mcp.json`, or user `~/.claude.json`)
- **Enhanced Visual Display**: Beautiful colored status with Unicode symbols and borders
- **Dynamic Raycast Dropdowns**: Auto-populated server selection menus that update automatically
- **Interactive Selection**: Numbered menus for easy server selection
- **Multiple Raycast Interfaces**: Text input, dropdowns, and interactive options
- **Status Monitoring**: View active and disabled servers with timestamps and source file information
- **Environment Variable Support**: Secure handling of API keys, tokens, and other credentials
- **Zero Configuration Loss**: Never lose your MCP server setups - perfect restoration guaranteed

## 📁 Scripts Overview

### Core Scripts

| Script | Purpose | Usage |
|--------|---------|--------|
| `toggle-mcp-server.sh` | **Main CLI** - Enhanced status display with colors/borders | Terminal operations |
| `add-mcp-server.sh` | **Add New Servers** - Interactive server addition with validation | Add servers active or inactive |
| `raycast-mcp-master.sh` | **Unified Raycast** - All operations in one interface | Text input for server names |
| `raycast-mcp-manager.py` | **Status Display** - Read-only server viewer | Status monitoring |

### Dynamic Dropdown Scripts (NEW) 

| Script | Purpose | Usage |
|--------|---------|--------|
| `raycast-disable-server.py` | **Generator** - Creates disable dropdown script | Run to update disable options |
| `raycast-enable-server.py` | **Generator** - Creates enable dropdown script | Run to update enable options |
| `raycast-disable-mcp-server.py` | **Auto-Generated** - Disable with dropdown | Raycast dropdown selection |
| `raycast-enable-mcp-server.py` | **Auto-Generated** - Enable with dropdown | Raycast dropdown selection |
| `update-raycast-dropdowns.sh` | **Convenience** - Updates both generators | Refresh dropdowns |

### Interactive Scripts

| Script | Purpose | Usage |
|--------|---------|--------|
| `raycast-mcp-dynamic.py` | **Interactive** - Numbered server selection | Enhanced UX with menus |

### Configuration Files

| File | Purpose |
|------|---------|
| `~/.claude.json` | Claude Code configuration (auto-detected) |
| `~/.mcp-toggle-config.json` | Disabled servers storage |

## 🔧 Installation

1. **Clone/Download** the scripts to your preferred directory (e.g., `~/Scripts/MCP-Toggle/`)
2. **Make executable**:
   ```bash
   chmod +x ~/Scripts/MCP-Toggle/*.sh
   ```
3. **For Raycast users**: Add the Raycast scripts to your Raycast script directory

## 📝 Command Line Usage

### Basic Commands

```bash
# Show all servers (active and disabled)
./toggle-mcp-server.sh status

# Disable a specific server
./toggle-mcp-server.sh disable server-name

# Enable a specific server
./toggle-mcp-server.sh enable server-name

# Disable ALL active servers
./toggle-mcp-server.sh disable-all

# Enable ALL disabled servers
./toggle-mcp-server.sh enable-all

# List only disabled servers
./toggle-mcp-server.sh list-disabled

# Show help
./toggle-mcp-server.sh help
```

### Examples

```bash
# Disable the desktop-commander server
./toggle-mcp-server.sh disable desktop-commander

# Check what servers are active
./toggle-mcp-server.sh status

# Re-enable the desktop-commander server
./toggle-mcp-server.sh enable desktop-commander

# Disable all servers for a clean Claude session
./toggle-mcp-server.sh disable-all

# Restore all your servers
./toggle-mcp-server.sh enable-all
```

### Adding New Servers

Use the interactive `add-mcp-server.sh` script to add new MCP servers:

```bash
# Run the interactive add script
./add-mcp-server.sh

# Get help with input formatting
./add-mcp-server.sh --help
```

**Key Points:**
- **No quotes needed** - just type values directly
- Server names: use lowercase with hyphens (e.g., `my-server`)
- Commands: enter executable name or full path
- Arguments: one per line, no special formatting needed
- Environment variables: `KEY=value` format
- Choose to start active or inactive

**Example Flow:**
```
Server name: my-mcp-server
Command: npx
Arg 0: @my/mcp-package
Arg 1: --port=3000
Arg 2: [press Enter to finish]
Does this server need environment variables? n
Start server active? n
```

## 🎯 Raycast Integration

### Available Raycast Scripts

#### Traditional Interface
1. **`raycast-mcp-master.sh`** - *Unified Controller*
   - Actions: Status, Disable Server, Enable Server, Disable ALL, Enable ALL
   - Requires manual server name input
   - Color-coded output

2. **`raycast-mcp-manager.py`** - *Status Display*
   - Actions: List Servers, Show Disabled
   - Read-only server viewer
   - Clean formatted output

#### Dynamic Dropdown Interface (NEW)
3. **`raycast-disable-mcp-server.py`** - *Disable with Dropdown*
   - Pre-populated dropdown of active servers
   - No typing required - just select from list
   - Auto-generated from current server state

4. **`raycast-enable-mcp-server.py`** - *Enable with Dropdown*
   - Pre-populated dropdown of disabled servers
   - Select from available disabled servers
   - Auto-generated from current server state

5. **`update-raycast-dropdowns.sh`** - *Refresh Dropdowns*
   - Updates both dropdown scripts with current server lists
   - Run after changing server configurations
   - Maintains up-to-date dropdown options

#### Interactive Interface
6. **`raycast-mcp-dynamic.py`** - *Interactive Selection*
   - Numbered menu selection for servers
   - Enhanced user experience
   - Works well for users who prefer guided selection

### Raycast Setup

1. Copy scripts to your Raycast script directory
2. Scripts will auto-appear in Raycast with proper metadata
3. For **dropdown scripts**: Run `update-raycast-dropdowns.sh` first to populate options
4. **Recommended workflow**:
   - Use dropdown scripts for daily server management
   - Use `update-raycast-dropdowns.sh` when server config changes
   - Use master script for bulk operations

## 🗂️ How It Works

### Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Raycast UI    │───▶│  Master Scripts  │───▶│ toggle-mcp-     │
│                 │    │                  │    │ server.sh       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │ ~/.claude.json  │◀───│  Configuration  │
                       │ (active)        │    │  Management     │
                       └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                              ┌─────────────────┐
                                              │~/.mcp-toggle-   │
                                              │config.json      │
                                              │(disabled)       │
                                              └─────────────────┘
```

### Server States

- **Active**: Listed in `~/.claude.json` under `mcpServers`
- **Disabled**: Moved to `~/.mcp-toggle-config.json` with timestamp
- **Configuration**: Preserved with command, args, and metadata

### File Structure

```
~/.claude.json                 # Claude Code main config
{
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "command",
      "args": ["arg1", "arg2"]
    }
  }
}

~/.mcp-toggle-config.json      # Disabled servers backup
{
  "server-name": {
    "command": "full command string",
    "disabled_at": "2025-08-23T17:41:53Z"
  }
}
```

## 🔧 Technical Improvements (v3.0)

### Complete Configuration Preservation
Unlike earlier versions that only saved commands as concatenated strings, the current system preserves:
- Full server configuration objects with all fields
- The `type` field (required "stdio" value)
- Proper separation of `command` and `args` arrays
- Environment variables with secure storage
- Source configuration file tracking

### Directory-Aware Configuration Detection
The scripts automatically detect and use the correct Claude configuration file:
1. **Local `.claude.json`** in current directory (project-specific)
2. **Local `.mcp.json`** files for project configurations
3. **User `~/.claude.json`** as fallback (global configuration)

This ensures the scripts work correctly whether you're in your home directory, a project folder, or any subdirectory.

### Enhanced Status Display
- Shows which configuration file is being used
- Indicates servers with environment variables `[env]`
- Displays source file for disabled servers when different from current config
- Color-coded output for better readability

### Dynamic Raycast Integration
- Generator scripts automatically create dropdown menus from current server state
- No more hardcoded server lists in Raycast scripts
- Updates automatically after enable/disable operations
- Maintains current server state in dropdown options

## 🎨 Current Server Inventory

As of last run, your setup includes:

### Active Servers (17)
- `reddit` - Reddit API integration
- `fastmail` - Fastmail email management
- `desktop-commander` - Desktop automation
- `iterm-mcp` - iTerm terminal integration
- `browsermcp` - Browser automation
- `apple-mcp` - Apple services integration
- `apple-reminders` - Reminders app integration
- `notion` - Notion workspace management
- `peekaboo` - Screen capture and analysis
- `paperless` - Document management
- `context7` - Documentation context
- `mcp-reddit-companion` - Enhanced Reddit features
- `flights` - Flight information
- `mcp-obsidian` - Obsidian vault integration
- `youtube` - YouTube data access
- `google-maps` - Maps and location services
- `hass-mcp` - Home Assistant integration

## 🔍 Troubleshooting

### Common Issues

**Q: Scripts show "No MCP servers configured"**
- **A**: Check if `~/.claude.json` exists and contains `mcpServers` section

**Q: Server won't disable**
- **A**: Ensure the server name exactly matches what's shown in `status`

**Q: Changes don't take effect**
- **A**: Restart Claude Code after making changes

**Q: Permission errors**
- **A**: Make sure scripts are executable: `chmod +x *.sh`

### Debug Steps

1. **Check Configuration**:
   ```bash
   cat ~/.claude.json | grep -A 10 mcpServers
   ```

2. **Verify Script Permissions**:
   ```bash
   ls -la ~/Scripts/MCP-Toggle/*.sh
   ```

3. **Test Status Command**:
   ```bash
   ./toggle-mcp-server.sh status
   ```

## 🔧 Advanced Usage

### Custom Workflows

**Development Mode** (minimal servers):
```bash
# Disable all except essential
./toggle-mcp-server.sh disable-all
./toggle-mcp-server.sh enable desktop-commander
./toggle-mcp-server.sh enable fastmail
```

**Full Power Mode** (all servers):
```bash
./toggle-mcp-server.sh enable-all
```

**Clean Session** (no MCP servers):
```bash
./toggle-mcp-server.sh disable-all
```

### Automation

**Add to .zshrc for quick access**:
```bash
alias mcp-status='~/Scripts/MCP-Toggle/toggle-mcp-server.sh status'
alias mcp-disable-all='~/Scripts/MCP-Toggle/toggle-mcp-server.sh disable-all'
alias mcp-enable-all='~/Scripts/MCP-Toggle/toggle-mcp-server.sh enable-all'
```

## 📂 Directory Structure

```
~/Scripts/MCP-Toggle/
├── toggle-mcp-server.sh              # Main CLI script (enhanced visuals)
├── add-mcp-server.sh                 # Interactive new server addition
├── raycast-mcp-master.sh             # Unified Raycast controller
├── raycast-mcp-manager.py            # Python status viewer
├── raycast-mcp-dynamic.py            # Interactive server selection
│
├── raycast-disable-server.py         # Generator for disable dropdown
├── raycast-enable-server.py          # Generator for enable dropdown  
├── raycast-disable-mcp-server.py     # Auto-generated disable script
├── raycast-enable-mcp-server.py      # Auto-generated enable script
├── update-raycast-dropdowns.sh       # Update dropdown options
│
├── raycast-update-mcp.sh             # MCP update script (separate)
├── backup/                           # Deprecated scripts
│   ├── raycast-toggle-mcp.sh
│   └── raycast-toggle-mcp-wrapper.sh
└── README.md                         # This documentation
```

## 🚨 Important Notes

- **Always Backup**: Your Claude config is automatically backed up before changes
- **Restart Required**: Claude Code must be restarted for changes to take effect
- **Case Sensitive**: Server names are case-sensitive
- **Safe Operations**: All operations preserve your original server configurations
- **No Data Loss**: Disabled servers retain all their settings and can be perfectly restored

## 📋 Quick Reference

| Want to... | Command | Raycast Alternative |
|------------|---------|-------------------|
| See all servers | `./toggle-mcp-server.sh status` | "MCP Manager" → List Servers |
| **Add new server** | `./add-mcp-server.sh` | *Terminal only* |
| Disable one server | `./toggle-mcp-server.sh disable SERVER_NAME` | **"Disable MCP Server"** (dropdown) |
| Enable one server | `./toggle-mcp-server.sh enable SERVER_NAME` | **"Enable MCP Server"** (dropdown) |
| Disable everything | `./toggle-mcp-server.sh disable-all` | "MCP Master Controller" → Disable ALL |
| Enable everything | `./toggle-mcp-server.sh enable-all` | "MCP Master Controller" → Enable ALL |
| Update dropdowns | `./update-raycast-dropdowns.sh` | **"Update MCP Raycast Dropdowns"** |

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify file permissions and paths
3. Ensure Claude Code is properly configured
4. Check that your installation directory contains all required files

---

**Version**: 3.0  
**Last Updated**: August 23, 2025  
**Compatibility**: Claude Code + macOS  
**New Features**: Enhanced visual display, dynamic Raycast dropdowns, interactive selection menus