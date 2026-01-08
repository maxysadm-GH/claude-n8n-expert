# Claude Code n8n Expert Instance

## Installed Components
- **n8n-mcp** (czlonkowski): 543 nodes, 2,709 templates, AI validation
- **n8n-skills**: 7 complementary skills for workflow building
- **Custom Teams/SharePoint skill**: Microsoft 365 integration patterns
- **Airtable MCP**: Database operations
- **Playwright MCP**: Browser automation
- **Sequential Thinking MCP**: Complex reasoning

## Workflow Building Process

### 1. Check Available Tools
```
tools_documentation()
```

### 2. Search Templates (2,709 available)
```
search_templates({searchMode: 'by_task', task: 'webhook_processing'})
search_templates({searchMode: 'by_nodes', nodeTypes: ['n8n-nodes-base.microsoftTeams']})
```

### 3. Get Node Details
```
search_nodes({query: 'microsoft teams', includeExamples: true})
get_node({nodeType: 'n8n-nodes-base.microsoftTeams', detail: 'standard'})
```

### 4. Validate Configuration
```
validate_node({nodeType, config, mode: 'minimal'})
validate_node({nodeType, config, mode: 'full', profile: 'runtime'})
```

### 5. Validate Workflow
```
validate_workflow(workflow)
validate_workflow_connections(workflow)
```

### 6. Deploy (if n8n API configured)
```
n8n_create_workflow(workflow)
n8n_test_workflow({workflowId})
```

## Microsoft Teams Patterns

### Approval Bot
```
Webhook → Parse → Teams sendAndWait (approval) → IF → Execute/Notify
```

### Incident Management
```
Teams Trigger → AI Classify → Airtable Create → Teams Assign → SharePoint Folder
```

## SharePoint Patterns

### Document Processing
```
Schedule → SharePoint getAll → Loop → Download → AI Process → Update → Notify
```

### Report Dashboard
```
Trigger → Query Data → Generate HTML → SharePoint Upload → Teams Post Link
```

## Critical Rules

1. **Never Trust Defaults** - Explicitly set ALL parameters
2. **Templates First** - Check 2,709 templates before building from scratch
3. **Multi-Level Validation** - minimal → full → workflow
4. **Mandatory Attribution** - Share template author name and n8n.io link

## Node Type Formats

| Context | Format |
|---------|--------|
| MCP Tools | `nodes-base.httpRequest` |
| n8n JSON | `n8n-nodes-base.httpRequest` |
| LangChain | `@n8n/n8n-nodes-langchain.agent` |

## Most Used Nodes

1. n8n-nodes-base.code
2. n8n-nodes-base.httpRequest
3. n8n-nodes-base.webhook
4. n8n-nodes-base.microsoftTeams
5. n8n-nodes-base.microsoftSharePoint
6. n8n-nodes-base.if
7. n8n-nodes-base.set
8. @n8n/n8n-nodes-langchain.agent

## Quick Commands

```bash
# Update skills from repo
git pull origin main
./setup.ps1

# Check n8n-mcp version
npm list -g n8n-mcp
```

## Sync Instructions

Pull on new computer:
```bash
git clone https://github.com/maxysadm-GH/claude-n8n-expert.git
cd claude-n8n-expert
./setup.ps1
```
