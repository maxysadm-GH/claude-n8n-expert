# Claude Code n8n Expert - Windows Setup Script
# Run: .\setup.ps1

Write-Host "=== Claude Code n8n Expert Setup ===" -ForegroundColor Cyan

# Check Node.js
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Node.js not found. Install from https://nodejs.org" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Node.js found: $(node --version)" -ForegroundColor Green

# Install n8n-mcp globally
Write-Host "Installing n8n-mcp..." -ForegroundColor Yellow
npm install -g n8n-mcp
Write-Host "✓ n8n-mcp installed" -ForegroundColor Green

# Define paths
$ClaudeDesktopConfig = "$env:APPDATA\Claude\claude_desktop_config.json"
$ClaudeSkillsDir = "$env:USERPROFILE\.claude\skills\user"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Create skills directory if needed
if (!(Test-Path $ClaudeSkillsDir)) {
    New-Item -ItemType Directory -Path $ClaudeSkillsDir -Force | Out-Null
}

# Copy Claude Code MCP config
$ClaudeCodeMcp = "$env:USERPROFILE\.claude\mcp.json"
$McpSource = Join-Path $ScriptDir "configs\claude-code-mcp.json"
if (Test-Path $McpSource) {
    $McpConfig = Get-Content $McpSource -Raw | ConvertFrom-Json
    
    # Preserve existing Airtable key if present
    if (Test-Path $ClaudeCodeMcp) {
        $ExistingMcp = Get-Content $ClaudeCodeMcp -Raw | ConvertFrom-Json
        if ($ExistingMcp.mcpServers.airtable.env.AIRTABLE_API_KEY -and $ExistingMcp.mcpServers.airtable.env.AIRTABLE_API_KEY -notlike '*${*') {
            $McpConfig.mcpServers.airtable.env.AIRTABLE_API_KEY = $ExistingMcp.mcpServers.airtable.env.AIRTABLE_API_KEY
        }
    }
    
    $McpConfig | ConvertTo-Json -Depth 10 | Set-Content $ClaudeCodeMcp
    Write-Host "✓ Claude Code MCP config installed" -ForegroundColor Green
    
    # Check if Airtable key needs to be set
    if ($McpConfig.mcpServers.airtable.env.AIRTABLE_API_KEY -like '*${*') {
        Write-Host ""
        Write-Host "NOTE: Airtable API key not configured." -ForegroundColor Yellow
        Write-Host "Edit $ClaudeCodeMcp and replace the placeholder, or run:" -ForegroundColor Yellow
        Write-Host '  $env:AIRTABLE_API_KEY = "your-key"' -ForegroundColor Gray
    }
}

# Copy skills
Write-Host "Installing n8n skills..." -ForegroundColor Yellow
$SkillsSource = Join-Path $ScriptDir "skills"
if (Test-Path $SkillsSource) {
    Copy-Item -Path "$SkillsSource\*" -Destination $ClaudeSkillsDir -Recurse -Force
    Write-Host "✓ Skills installed to $ClaudeSkillsDir" -ForegroundColor Green
}

# Check if n8n-skills repo exists, clone if not
$N8nSkillsPath = Join-Path (Split-Path $ScriptDir -Parent) "n8n-skills"
if (!(Test-Path $N8nSkillsPath)) {
    Write-Host "Cloning n8n-skills repository..." -ForegroundColor Yellow
    Push-Location (Split-Path $ScriptDir -Parent)
    git clone https://github.com/czlonkowski/n8n-skills.git
    Pop-Location
}

# Copy n8n-skills to Claude
if (Test-Path "$N8nSkillsPath\skills") {
    Copy-Item -Path "$N8nSkillsPath\skills\*" -Destination $ClaudeSkillsDir -Recurse -Force
    Write-Host "✓ n8n-skills installed" -ForegroundColor Green
}

# Update Claude Desktop config
Write-Host "Updating Claude Desktop config..." -ForegroundColor Yellow
$ConfigTemplate = Get-Content (Join-Path $ScriptDir "configs\mcp-config.json") -Raw

# Get npx path
$NpxPath = (Get-Command npx).Source -replace '\\', '\\\\'

# Replace npx command for Windows
$ConfigJson = $ConfigTemplate | ConvertFrom-Json
foreach ($server in $ConfigJson.mcpServers.PSObject.Properties) {
    if ($server.Value.command -eq "npx") {
        $server.Value.command = $NpxPath
    }
}

# Preserve existing Airtable key if present
if (Test-Path $ClaudeDesktopConfig) {
    $ExistingConfig = Get-Content $ClaudeDesktopConfig -Raw | ConvertFrom-Json
    if ($ExistingConfig.mcpServers.airtable.env.AIRTABLE_API_KEY) {
        $ConfigJson.mcpServers.airtable.env.AIRTABLE_API_KEY = $ExistingConfig.mcpServers.airtable.env.AIRTABLE_API_KEY
    }
}

# Add preferences
$ConfigJson | Add-Member -NotePropertyName "preferences" -NotePropertyValue @{chromeExtensionEnabled=$true} -Force

# Write config
$ConfigJson | ConvertTo-Json -Depth 10 | Set-Content $ClaudeDesktopConfig
Write-Host "✓ Claude Desktop config updated" -ForegroundColor Green

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "Restart Claude Desktop to apply changes." -ForegroundColor Yellow
Write-Host ""
Write-Host "Installed:" -ForegroundColor White
Write-Host "  - n8n-mcp (543 nodes, 2709 templates)" -ForegroundColor Gray
Write-Host "  - n8n-skills (7 core workflow skills)" -ForegroundColor Gray
Write-Host "  - VHC ShipStation integration skill" -ForegroundColor Gray
Write-Host "  - Fishbowl inventory skill" -ForegroundColor Gray
Write-Host "  - Azure Logic Apps skill" -ForegroundColor Gray
Write-Host "  - Shopify Bulk API skill" -ForegroundColor Gray
Write-Host "  - HubSpot CRM API skill" -ForegroundColor Gray
Write-Host "  - Vosges ICP Validator skill" -ForegroundColor Gray
Write-Host "  - Teams/SharePoint expert skill" -ForegroundColor Gray
Write-Host "  - Airtable, Sequential Thinking MCPs" -ForegroundColor Gray
