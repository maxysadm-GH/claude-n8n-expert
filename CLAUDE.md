# CLAUDE.md - n8n Expert Instance

## Project Overview
This repository configures Claude Code as an n8n workflow automation expert with deep knowledge of 543 nodes, 2,709 templates, and specialized integration skills for enterprise workflows.

## Installed Components

### MCP Servers (3 total)
| Server | Purpose | Key Capabilities |
|--------|---------|------------------|
| **n8n-mcp** | Workflow automation | 543 nodes, 2,709 templates, AI validation |
| **airtable-mcp** | Database operations | CRUD, views, formulas |
| **sequential-thinking** | Complex reasoning | Step-by-step analysis |

### Custom Skills (14 total)

#### Core n8n Skills (7)
1. **n8n-workflow-builder** - Full workflow creation with validation
2. **n8n-template-finder** - Search 2,709 templates by task/nodes
3. **n8n-node-expert** - Node configuration with examples
4. **n8n-debugging** - Troubleshoot failing workflows
5. **n8n-best-practices** - Performance and security patterns
6. **n8n-api-integration** - Connect any REST/GraphQL API
7. **n8n-langchain-agent** - AI agent workflows

#### Integration Skills (7)
1. **teams-sharepoint-integration** - Microsoft 365 patterns
2. **shipstation-integration** - Order/shipping automation
3. **fishbowl-integration** - Inventory sync workflows
4. **azure-logic-apps** - Hybrid automation patterns
5. **shopify-bulk-api** - E-commerce bulk operations
6. **hubspot-integration** - CRM automation
7. **vosges-icp-validator** - Ice pack determination workflows

## Workflow Building Process

### Step 1: Check Available Tools
```javascript
tools_documentation()
```

### Step 2: Search Templates (2,709 available)
```javascript
// By task description
search_templates({searchMode: 'by_task', task: 'webhook_processing'})

// By specific nodes
search_templates({searchMode: 'by_nodes', nodeTypes: ['n8n-nodes-base.microsoftTeams']})

// By category
search_templates({searchMode: 'by_category', category: 'sales'})
```

### Step 3: Get Node Details
```javascript
// Search nodes
search_nodes({query: 'microsoft teams', includeExamples: true})

// Get specific node documentation
get_node({nodeType: 'n8n-nodes-base.microsoftTeams', detail: 'standard'})
get_node({nodeType: 'n8n-nodes-base.httpRequest', detail: 'full'})
```

### Step 4: Multi-Level Validation
```javascript
// Minimal - Quick structure check
validate_node({nodeType, config, mode: 'minimal'})

// Full - Complete parameter validation
validate_node({nodeType, config, mode: 'full', profile: 'runtime'})

// Workflow-level
validate_workflow(workflow)
validate_workflow_connections(workflow)
```

### Step 5: Deploy (if n8n API configured)
```javascript
n8n_create_workflow(workflow)
n8n_test_workflow({workflowId})
n8n_activate_workflow({workflowId, active: true})
```

## Common Workflow Patterns

### Microsoft Teams Patterns

#### Approval Bot
```
Webhook → Parse Request → Teams sendAndWait (approval) → IF approved → Execute Action → Teams Notify
```

#### Incident Management
```
Teams Trigger → AI Classify Severity → Airtable Create → Teams Assign Owner → SharePoint Create Folder
```

### SharePoint Patterns

#### Document Processing
```
Schedule → SharePoint getAll → Loop Items → Download File → AI Process → Update Metadata → Teams Notify
```

#### Report Dashboard
```
Trigger → Query Data Sources → Generate HTML Report → SharePoint Upload → Teams Post Link
```

### ShipStation Patterns

#### Order Sync
```
Webhook (new order) → Parse → Fishbowl Check Inventory → IF in stock → ShipStation Create → Teams Notify
```

#### Weather-Based Routing
```
Schedule → Get Orders → Weather API Check → Classify Ice Pack Need → Update Custom Fields → Route to Carrier
```

## Node Type Formats

| Context | Format | Example |
|---------|--------|---------|
| MCP Tools | No prefix | `nodes-base.httpRequest` |
| n8n JSON | Full prefix | `n8n-nodes-base.httpRequest` |
| LangChain | Scoped | `@n8n/n8n-nodes-langchain.agent` |
| Community | Prefix | `n8n-nodes-community.customNode` |

## Most Used Nodes

| Rank | Node | Use Case |
|------|------|----------|
| 1 | `n8n-nodes-base.code` | Custom JavaScript logic |
| 2 | `n8n-nodes-base.httpRequest` | API calls |
| 3 | `n8n-nodes-base.webhook` | Trigger workflows |
| 4 | `n8n-nodes-base.if` | Conditional logic |
| 5 | `n8n-nodes-base.set` | Transform data |
| 6 | `n8n-nodes-base.microsoftTeams` | Teams messaging |
| 7 | `n8n-nodes-base.microsoftSharePoint` | Document management |
| 8 | `@n8n/n8n-nodes-langchain.agent` | AI agents |
| 9 | `n8n-nodes-base.airtable` | Database ops |
| 10 | `n8n-nodes-base.merge` | Combine data |

## Critical Rules

### 1. Never Trust Defaults
Always explicitly set ALL parameters. n8n defaults can cause unexpected behavior.

### 2. Templates First
Check 2,709 templates before building from scratch. Save time and avoid edge cases.

### 3. Multi-Level Validation
Always validate: `minimal → full → workflow`

### 4. Mandatory Attribution
When using templates, share:
- Template author name
- Link to n8n.io template page

### 5. Credentials Never Hardcoded
Use n8n credential store. Reference by ID, never by value.

## Project Structure

```
claude-n8n-expert/
├── CLAUDE.md              # This file
├── setup.ps1              # One-click installation script
├── .claude/
│   └── settings.json      # MCP server configuration
├── skills/
│   ├── n8n-workflow-builder.md
│   ├── n8n-template-finder.md
│   ├── n8n-node-expert.md
│   ├── n8n-debugging.md
│   ├── n8n-best-practices.md
│   ├── n8n-api-integration.md
│   ├── n8n-langchain-agent.md
│   ├── teams-sharepoint-integration.md
│   ├── shipstation-integration.md
│   ├── fishbowl-integration.md
│   ├── azure-logic-apps.md
│   ├── shopify-bulk-api.md
│   ├── hubspot-integration.md
│   └── vosges-icp-validator.md
└── examples/
    ├── approval-workflow.json
    ├── incident-management.json
    └── document-processing.json
```

## Setup on New Computer

### Quick Setup (Recommended)
```powershell
git clone https://github.com/maxysadm-GH/claude-n8n-expert.git
cd claude-n8n-expert
./setup.ps1
```

### Manual Setup
1. Install n8n-mcp globally:
   ```bash
   npm install -g n8n-mcp
   ```
2. Copy `.claude/settings.json` to Claude Code settings
3. Restart Claude Code

### Verify Installation
```bash
# Check n8n-mcp version
npm list -g n8n-mcp

# Test MCP connection
claude-code --mcp-test
```

## Environment Variables

Optional for API deployments:
```bash
N8N_API_URL=https://your-n8n-instance.com
N8N_API_KEY=your-api-key
```

## Git Workflow

```bash
# Pull latest skills
git pull origin main
./setup.ps1

# After adding new skills
git add skills/
git commit -m "feat: add new integration skill"
git push
```

## Troubleshooting

### MCP Server Not Responding
```powershell
# Restart Claude Code
# Or run setup again
./setup.ps1
```

### Template Search Returns Empty
```javascript
// Use broader search
search_templates({searchMode: 'by_task', task: 'automation'})
// Or check specific category
search_templates({searchMode: 'by_category', category: 'productivity'})
```

### Validation Errors
```javascript
// Get detailed error info
validate_node({nodeType, config, mode: 'full', profile: 'development'})
```

## Links & Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Community Templates](https://n8n.io/workflows/)
- [MCP Protocol Spec](https://modelcontextprotocol.io/)
- [GitHub Repository](https://github.com/maxysadm-GH/claude-n8n-expert)
