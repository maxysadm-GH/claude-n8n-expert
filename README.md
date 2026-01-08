# Claude Code n8n Expert

Portable Claude Code configuration for n8n workflow building with Microsoft Teams/SharePoint integration.

## What's Included

- **n8n-mcp** - 543 nodes, 2,709 templates, AI validation
- **n8n-skills** - 7 complementary Claude Code skills
- **Teams/SharePoint skill** - Microsoft 365 integration patterns
- **Airtable MCP** - Database operations
- **Sequential Thinking MCP** - Complex reasoning
- **Browser**: Use `claude --chrome` flag (no Playwright needed)

## Quick Start

### Windows
```powershell
git clone https://github.com/maxysadm-GH/claude-n8n-expert.git
cd claude-n8n-expert
.\setup.ps1
```

### macOS/Linux
```bash
git clone https://github.com/maxysadm-GH/claude-n8n-expert.git
cd claude-n8n-expert
chmod +x setup.sh
./setup.sh
```

## Multi-Computer Sync

Pull updates on any computer:
```bash
cd claude-n8n-expert
git pull origin main
.\setup.ps1  # or ./setup.sh
```

## Configuration

Copy `.env.template` to `.env` and fill in your keys:
- `N8N_API_URL` - Your n8n instance URL
- `N8N_API_KEY` - Your n8n API key
- `AIRTABLE_API_KEY` - Airtable PAT
- `OPENROUTER_API_KEY` - For AI workflows

## Usage

After setup, Claude Code will have access to:

### Template Search
```
search_templates({searchMode: 'by_task', task: 'approval workflow'})
search_templates({searchMode: 'by_nodes', nodeTypes: ['n8n-nodes-base.microsoftTeams']})
```

### Node Configuration
```
get_node({nodeType: 'n8n-nodes-base.microsoftTeams', detail: 'standard'})
validate_node({nodeType, config, mode: 'full'})
```

### Workflow Validation
```
validate_workflow(workflow)
validate_workflow_connections(workflow)
```

## Skills Installed

| Skill | Purpose |
|-------|---------|
| n8n-expression-syntax | {{}} patterns, $json/$node |
| n8n-mcp-tools-expert | Tool selection, validation |
| n8n-workflow-patterns | 5 proven architectures |
| n8n-validation-expert | Error interpretation |
| n8n-node-configuration | Operation-aware config |
| n8n-code-javascript | Code node patterns |
| n8n-code-python | Python limitations |
| n8n-teams-sharepoint-expert | Microsoft 365 integration |

## License

MIT
