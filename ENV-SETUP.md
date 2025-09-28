# MCP Environment Variables Setup

## Overview

Some MCP servers require environment variables (API keys, tokens, URLs) to function properly. The MCP Toggle system now includes a secure way to manage these credentials.

## Quick Start for Home Assistant (hass-mcp)

1. **Setup your credentials:**
   ```bash
   ./setup-mcp-env.sh setup hass-mcp
   ```
   You'll be prompted for:
   - Your Home Assistant URL (e.g., `http://homeassistant.local:8123`)
   - Your Long-Lived Access Token (get from HA Settings → Your Profile → Long-Lived Access Tokens)

2. **Test the connection:**
   ```bash
   ./setup-mcp-env.sh test hass-mcp
   ```

3. **Enable the server:**
   ```bash
   ./toggle-mcp-server.sh enable hass-mcp
   ```

4. **Restart Claude Code** for changes to take effect

## How It Works

### Environment Storage
- Credentials are stored in `~/.mcp-env.json` with restricted permissions (600)
- Separate from the main Claude configuration for security
- Automatically applied when enabling servers

### Automatic Application
When you enable a server:
1. The toggle script checks for saved environment variables
2. If found, they're automatically added to the server's configuration
3. The server gets the complete configuration including env vars

### Security
- Credentials are stored separately from the main config
- File permissions restrict access to your user only
- Tokens are masked when displayed in status outputs

## File Structure

```
~/.mcp-env.json           # Environment variables (secure)
~/.mcp-toggle-config.json # Saved server configurations
~/.claude.json            # Active Claude configuration
```

## Commands

### Setup Environment Variables
```bash
./setup-mcp-env.sh setup hass-mcp
```
- Interactive prompts for credentials
- Updates existing values or sets new ones
- Automatically updates active server if enabled

### Test Connection
```bash
./setup-mcp-env.sh test hass-mcp
```
- Verifies credentials work
- Shows Home Assistant version and location

### View Status
```bash
./setup-mcp-env.sh status
```
- Shows all configured environment variables
- Masks sensitive values for security

## Troubleshooting

### "No Home Assistant token provided" Error
This means the environment variables aren't set. Run:
```bash
./setup-mcp-env.sh setup hass-mcp
```

### After Setting Environment Variables
1. If hass-mcp was already enabled, the setup script will update it automatically
2. Always restart Claude Code after configuration changes

### Changing Credentials
Simply run the setup command again. It will show current values and let you update them.

## Supported Servers

Currently supported:
- **hass-mcp** - Home Assistant integration

More servers can be added to `setup-mcp-env.sh` as needed.

## Example Flow

```bash
# 1. Disable all servers
./toggle-mcp-server.sh disable-all

# 2. Setup Home Assistant credentials
./setup-mcp-env.sh setup hass-mcp
# Enter URL: http://homeassistant.local:8123
# Enter Token: [your-long-lived-token]

# 3. Test the connection
./setup-mcp-env.sh test hass-mcp
# ✓ Successfully connected to Home Assistant!

# 4. Enable the server
./toggle-mcp-server.sh enable hass-mcp
# ✓ Server 'hass-mcp' has been enabled

# 5. Restart Claude Code

# 6. Verify it works in Claude
# Try: "Turn on the living room lights"
```

## Notes

- Environment variables are preserved when disabling/re-enabling servers
- The setup script can update credentials at any time
- Each server can have its own set of environment variables
- The system is extensible for other servers that need credentials