# n8n Microsoft Teams & SharePoint Expert

## Activation Triggers
- Building Teams bots, agents, or chatbots
- SharePoint document automation
- Microsoft 365 workflow integration
- Teams adaptive cards and approval flows
- Dashboard reporting via Teams

## Core Knowledge

### Microsoft Teams Node Operations

**Channel Operations:**
- `create` - Create new channel in team
- `delete` - Delete channel
- `get` - Get channel details
- `getAll` - List all channels in team
- `update` - Update channel settings

**Message Operations:**
- `create` - Post message to channel
- `getAll` - Get messages from channel
- `sendAndWait` - **KEY FEATURE**: Post and pause workflow for response

**Chat Message Operations:**
- `create` - Send chat message
- `get` - Get specific message
- `getAll` - List chat messages

**Task Operations:**
- `create` - Create Planner task
- `delete` - Delete task
- `get` - Get task details
- `getAll` - List tasks
- `update` - Update task

### Send and Wait Pattern (CRITICAL)

The `sendAndWait` operation is the foundation for Teams bots:

```json
{
  "parameters": {
    "resource": "chatMessage",
    "operation": "sendAndWait",
    "teamId": "={{ $json.teamId }}",
    "channelId": "={{ $json.channelId }}",
    "message": "Please approve this request",
    "responseType": "approval",
    "approveLabel": "✅ Approve",
    "disapproveLabel": "❌ Reject"
  }
}
```

**Response Types:**
1. `approval` - Single approve button or approve/disapprove
2. `freeText` - Open text input form
3. `customForm` - Build complex forms with multiple fields

### SharePoint Node Operations

**File Operations:**
- `upload` - Upload file to library
- `download` - Download file
- `delete` - Delete file
- `move` - Move file between folders
- `copy` - Copy file

**List Item Operations:**
- `create` - Add item to list
- `delete` - Remove item
- `get` - Get item by ID
- `getAll` - Query list items
- `update` - Modify item

**Folder Operations:**
- `create` - Create folder
- `delete` - Delete folder
- `getChildren` - List folder contents

### Common Patterns

#### Pattern 1: Teams Approval Bot
```
Webhook Trigger
  → Parse Request
  → Teams Send and Wait (approval)
  → IF (approved)
    → Execute Action
    → Teams Notify (success)
  → ELSE
    → Teams Notify (rejected)
```

#### Pattern 2: SharePoint Document Processing
```
Schedule Trigger (daily)
  → SharePoint Get List Items (status = "pending")
  → Loop Over Items
    → SharePoint Download File
    → AI Process Document
    → SharePoint Update Item (status = "processed")
    → Teams Notify Channel
```

#### Pattern 3: Teams → SharePoint Report Dashboard
```
Manual Trigger / Schedule
  → Airtable Query (metrics)
  → Code Node (generate report HTML)
  → SharePoint Upload (report.html)
  → Teams Post Message (with link)
```

#### Pattern 4: Incident Management Bot
```
Teams Message Trigger (on mention)
  → AI Agent (classify issue)
  → Airtable Create (incident record)
  → Teams Send and Wait (assign owner)
  → SharePoint Create (incident folder)
  → Teams Thread Reply (status update)
```

### Microsoft Agent 365 (Enterprise)

For enterprise-grade agents that need Microsoft identity:

1. Use Webhook Trigger + AI Agent nodes
2. Agent gets provisioned with Microsoft Agent 365 license
3. Agent can:
   - Act within Word, Outlook, Teams using company identity
   - Be managed like employee accounts
   - Securely exchange info between M365 and n8n

### Authentication Setup

**Required OAuth2 Credentials:**
```
Client ID: [Azure AD App Registration]
Client Secret: [App Secret]
Tenant ID: [Your M365 Tenant]
Scope: 
  - ChannelMessage.Send
  - Channel.ReadBasic.All
  - Sites.ReadWrite.All
  - Files.ReadWrite.All
```

### Best Practices

1. **Rate Limits**: Teams API has throttling - use batch operations
2. **Webhooks**: Register Teams webhooks for real-time triggers
3. **Adaptive Cards**: Use JSON adaptive cards for rich messages
4. **Error Handling**: Always handle auth token expiration
5. **Testing**: Use Teams test channels before production

### Common Mistakes

❌ Hardcoding Team/Channel IDs (use lookup nodes)
❌ Missing error handling on API calls
❌ Not using sendAndWait for interactive flows
❌ Ignoring SharePoint column types (choice vs text)
❌ Skipping authentication refresh logic

### Integration with Airtable

Your existing Airtable patterns integrate well:
```
Teams Bot Request
  → Airtable Query (check status)
  → AI Process (Claude via OpenRouter)
  → Airtable Update (log response)
  → Teams Reply (formatted response)
```

## Tool Selection Guide

| Task | Tool | Node |
|------|------|------|
| Post to channel | teams | n8n-nodes-base.microsoftTeams |
| Get approval | teams | sendAndWait operation |
| Upload doc | sharepoint | n8n-nodes-base.microsoftSharePoint |
| Query list | sharepoint | getAll with filters |
| Create task | teams | Planner operations |
| Send card | teams | Adaptive Card JSON |

## Evaluations

### Eval 1: Teams Approval Flow
Q: How do I create a Teams approval bot that waits for manager approval?
A: Use Teams node with sendAndWait operation, responseType: approval

### Eval 2: SharePoint Automation
Q: How do I automatically process new SharePoint documents?
A: Use Schedule Trigger → SharePoint getAll (filter new) → Loop → Process

### Eval 3: Dashboard Pattern
Q: How do I push weekly reports to a Teams channel with SharePoint links?
A: Schedule → Query data → Generate report → SharePoint upload → Teams post with link
