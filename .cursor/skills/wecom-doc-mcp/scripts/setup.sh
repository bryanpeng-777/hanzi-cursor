#!/bin/bash
# WeCom Document MCP Service — Setup Script (self-contained)
# Source code is bundled inside this skill package, no git clone needed.
# Usage: bash setup.sh [install_dir]

set -e

INSTALL_DIR="${1:-$HOME/wecom-doc-mcp}"

# Resolve the skill directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$SKILL_DIR/source"

echo "🚀 WeCom Document MCP Service — Setup"
echo "======================================="
echo ""

# Step 1: Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js >=18"
    echo "   https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version too old ($(node -v)), requires >=18"
    exit 1
fi
echo "✅ Node.js $(node -v)"

# Step 2: Check bundled source exists
if [ ! -f "$SOURCE_DIR/package.json" ]; then
    echo "❌ Bundled source not found at $SOURCE_DIR"
    echo "   This skill package may be incomplete."
    exit 1
fi

# Step 3: Copy source to install directory
if [ -f "$INSTALL_DIR/package.json" ] && grep -q "wecom-doc-mcp" "$INSTALL_DIR/package.json" 2>/dev/null; then
    echo "📦 Updating existing installation at $INSTALL_DIR ..."
    cp -f "$SOURCE_DIR/package.json" "$INSTALL_DIR/"
    cp -f "$SOURCE_DIR/package-lock.json" "$INSTALL_DIR/" 2>/dev/null || true  # lock file may not exist
    cp -rf "$SOURCE_DIR/src/" "$INSTALL_DIR/src/"
else
    echo "📦 Installing to $INSTALL_DIR ..."
    mkdir -p "$INSTALL_DIR/src"
    cp -f "$SOURCE_DIR/package.json" "$INSTALL_DIR/"
    cp -f "$SOURCE_DIR/package-lock.json" "$INSTALL_DIR/" 2>/dev/null || true  # lock file may not exist
    cp -rf "$SOURCE_DIR/src/" "$INSTALL_DIR/src/"
fi

cd "$INSTALL_DIR"

# Step 4: Install npm dependencies
echo ""
echo "📦 Installing npm dependencies..."
npm install

# Step 5: Install Playwright Chromium
echo ""
echo "🌐 Installing Playwright Chromium..."
PLAYWRIGHT_OK=true
npx playwright install chromium || {
    echo ""
    echo "⚠️  ⚠️  Playwright Chromium install failed!"
    echo "   This is REQUIRED for the service to work."
    echo "   Please run manually after fixing the issue:"
    echo "   cd $INSTALL_DIR && npx playwright install chromium"
    echo "   Then re-run this setup script."
    echo ""
    PLAYWRIGHT_OK=false
}

# Step 6: Auto-detect AI tools and configure MCP (only if Playwright succeeded)
if [ "$PLAYWRIGHT_OK" = "false" ]; then
    echo "⚠️  Skipping MCP configuration because Playwright is not installed."
    echo "   Fix Playwright first, then re-run this script."
    exit 1
fi
echo ""
INDEX_JS="$INSTALL_DIR/src/index.js"

configure_mcp() {
    local config_file="$1"
    local tool_name="$2"
    local with_timeout="${3:-true}"

    if [ ! -f "$config_file" ]; then
        mkdir -p "$(dirname "$config_file")"
        if [ "$with_timeout" = "true" ]; then
            cat > "$config_file" << MCPEOF
{
  "mcpServers": {
    "wecom-doc": {
      "command": "node",
      "args": ["$INDEX_JS"],
      "timeout": 180000
    }
  }
}
MCPEOF
        else
            cat > "$config_file" << MCPEOF
{
  "mcpServers": {
    "wecom-doc": {
      "command": "node",
      "args": ["$INDEX_JS"]
    }
  }
}
MCPEOF
        fi
        echo "  ✅ $tool_name: created $config_file"
        return
    fi

    if grep -q "wecom-doc" "$config_file" 2>/dev/null; then
        echo "  ✅ $tool_name: already configured"
        return
    fi

    node -e "
const fs = require('fs');
try {
    const cfg = JSON.parse(fs.readFileSync('$config_file', 'utf-8'));
    cfg.mcpServers = cfg.mcpServers || {};
    const entry = { command: 'node', args: ['$INDEX_JS'] };
    if ('$with_timeout' === 'true') entry.timeout = 180000;
    cfg.mcpServers['wecom-doc'] = entry;
    fs.writeFileSync('$config_file', JSON.stringify(cfg, null, 2));
    console.log('  ✅ $tool_name: configured');
} catch(e) {
    console.log('  ⚠️  $tool_name: failed to update config (' + e.message + ')');
}
"
}

echo "🔍 Detecting AI tools..."
CONFIGURED=0

# CodeBuddy
if [ -d "$HOME/.codebuddy" ] || command -v codebuddy &> /dev/null 2>&1; then
    configure_mcp "$HOME/.codebuddy/mcp.json" "CodeBuddy"
    CONFIGURED=1
fi

# Cursor
if [ -d "$HOME/.cursor" ]; then
    configure_mcp "$HOME/.cursor/mcp.json" "Cursor"
    CONFIGURED=1
fi

# Claude Desktop (macOS)
if [ "$(uname)" = "Darwin" ] && [ -d "$HOME/Library/Application Support/Claude" ]; then
    configure_mcp "$HOME/Library/Application Support/Claude/claude_desktop_config.json" "Claude Desktop" "false"
    CONFIGURED=1
fi

# Windsurf
if [ -d "$HOME/.codeium/windsurf" ]; then
    configure_mcp "$HOME/.codeium/windsurf/mcp_config.json" "Windsurf"
    CONFIGURED=1
fi

# Default to CodeBuddy if nothing detected
if [ "$CONFIGURED" -eq 0 ]; then
    echo "  No AI tool detected, defaulting to CodeBuddy..."
    configure_mcp "$HOME/.codebuddy/mcp.json" "CodeBuddy (default)"
fi

# Step 7: Done
echo ""
echo "======================================="
echo "🎉 Installation complete!"
echo ""
echo "📌 Next step: RESTART your AI tool (close and reopen)"
echo "   After restart, just say '登录企微文档' or '帮我获取企微文档'"
echo "   AI will handle the login automatically."
echo ""
echo "📌 If auto-login doesn't work, run manually:"
echo "   cd $INSTALL_DIR && npm run login"
echo "======================================="
