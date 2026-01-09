# MBaCio Virtual Receptionist - Setup Guide

## Overview

This guide walks you through setting up the AI Virtual Receptionist system that:
1. Answers all incoming calls (Layer 1: Never lose a call)
2. Understands caller intent and validates identity (Layer 2)
3. Logs requests and sends email notifications (Layer 3)
4. Assesses priority based on SLA rules (Layer 4)
5. Attempts first call resolution using the knowledge base (Layer 5)

---

## Prerequisites

- [ ] Dialpad PRO account with admin access
- [ ] ElevenLabs account with Conversational AI (Starter plan+)
- [ ] n8n Cloud account (or self-hosted n8n)
- [ ] Supabase project (provided: MBACIO VOIP LAYER)
- [ ] OpenAI API key (for embeddings)
- [ ] SharePoint access to KB folder

---

## Step 1: Set Up Supabase Database

### 1.1 Run the Schema

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select project: **MBACIO VOIP LAYER**
3. Navigate to **SQL Editor**
4. Copy contents of `database/schema.sql`
5. Click **Run** to execute

This creates:
- `caller_identity` - Known contacts for validation
- `call_log` - All call records
- `kb_embeddings` - Knowledge base with vector search
- `email_notifications` - Email audit trail
- `workflow_errors` - n8n error logging

### 1.2 Verify Tables

Go to **Table Editor** and confirm all tables are created.

### 1.3 Get API Keys

1. Go to **Settings** > **API**
2. Note down:
   - **Project URL**: `https://fhhorzemcxtiifirbcia.supabase.co`
   - **anon/public key**: For n8n workflows
   - **service_role key**: For admin operations (keep secure!)

---

## Step 2: Configure n8n

### 2.1 Import Workflows

1. Go to your n8n instance
2. Click **Workflows** > **Import from File**
3. Import `workflows/01-call-handler.json`

### 2.2 Set Environment Variables

In n8n, go to **Settings** > **Variables** and add:

```
SUPABASE_URL=https://fhhorzemcxtiifirbcia.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
OPENAI_API_KEY=your_openai_key_here
```

### 2.3 Configure Email Credentials

1. Go to **Credentials** > **Add Credential**
2. Select **SMTP** or your email provider
3. Configure with your SMTP settings:
   - Host: Your SMTP server
   - Port: 587 (TLS) or 465 (SSL)
   - User: Your email address
   - Password: App password or SMTP password

### 2.4 Activate the Workflow

1. Open the imported workflow
2. Click **Active** toggle in top right
3. Note the webhook URL (you'll need this for ElevenLabs)

Webhook URL format: `https://your-n8n.app.n8n.cloud/webhook/elevenlabs-handler`

---

## Step 3: Set Up ElevenLabs Agent

### 3.1 Create New Agent

1. Log into [ElevenLabs](https://elevenlabs.io)
2. Go to **Conversational AI** > **Create Agent**
3. Name: "MBaCio Virtual Receptionist"

### 3.2 Configure System Prompt

Copy the system prompt from `elevenlabs/agent_config.md` into the agent configuration.

### 3.3 Add Tools

Add these tools (webhook configurations):

**Tool 1: validate_identity**
```json
{
  "name": "validate_identity",
  "webhook_url": "YOUR_N8N_WEBHOOK_URL",
  "description": "Validate caller identity against known contacts",
  "parameters": {
    "caller_name": "string (required)",
    "caller_email": "string",
    "callback_number": "string"
  }
}
```

**Tool 2: search_kb**
```json
{
  "name": "search_kb",
  "webhook_url": "YOUR_N8N_WEBHOOK_URL",
  "description": "Search knowledge base for solutions",
  "parameters": {
    "query": "string (required)",
    "product": "string",
    "error_message": "string"
  }
}
```

**Tool 3: assess_priority**
```json
{
  "name": "assess_priority",
  "webhook_url": "YOUR_N8N_WEBHOOK_URL",
  "description": "Determine issue priority and SLA",
  "parameters": {
    "issue_summary": "string (required)",
    "users_affected": "string",
    "business_impact": "string"
  }
}
```

### 3.4 Configure Voice

1. Select voice: **Rachel** (recommended) or custom
2. Settings:
   - Stability: 0.5
   - Similarity: 0.75

### 3.5 Configure Webhooks

Set the webhook URL to send events to n8n:
- Events: `conversation.started`, `tool_call`, `conversation.ended`
- URL: Your n8n webhook URL

### 3.6 Get SIP Details

Note the SIP endpoint provided by ElevenLabs for Dialpad configuration.

---

## Step 4: Configure Dialpad

### 4.1 Create SIP Trunk

1. Log into Dialpad Admin
2. Go to **Settings** > **Phone Numbers** > **SIP Trunking**
3. Create new SIP trunk pointing to ElevenLabs SIP endpoint

### 4.2 Configure Call Routing

1. Go to **Call Routing** > **Departments** or **Main Line**
2. Set up routing to forward to the ElevenLabs SIP trunk
3. Options:
   - Route all calls to AI
   - Route during off-hours only
   - Route when no one answers

---

## Step 5: Populate Knowledge Base

### 5.1 Add Sample KB Entry

The schema includes a sample Fishbowl article. Add more entries:

```sql
INSERT INTO kb_embeddings (title, content, category, product, document_type, source)
VALUES (
  'Your Article Title',
  'Step-by-step troubleshooting content...',
  'software',  -- category
  'ProductName',  -- product
  'troubleshooting',  -- document_type
  'manual'  -- source
);
```

### 5.2 Generate Embeddings (Future)

For semantic search, you'll need to generate embeddings using OpenAI:

```javascript
// Example: Generate embedding for KB article
const response = await fetch('https://api.openai.com/v1/embeddings', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${OPENAI_API_KEY}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model: 'text-embedding-3-small',
    input: 'Your article content here'
  })
});

const { data } = await response.json();
const embedding = data[0].embedding; // 1536-dimensional vector
```

### 5.3 Import Identity Data

1. Use `templates/identity_validation_template.csv` as a template
2. Add your known contacts
3. Import to Supabase via Table Editor > Import CSV

---

## Step 6: SharePoint Integration (Optional)

### 6.1 Azure App Registration

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** > **App registrations**
3. Create new registration:
   - Name: "n8n-sharepoint-integration"
   - Redirect URI: Your n8n OAuth callback URL

### 6.2 Configure Permissions

Add these Microsoft Graph permissions:
- `Sites.Read.All`
- `Files.Read.All`

### 6.3 Create n8n Credential

1. In n8n, add **Microsoft** credential
2. Enter Client ID, Tenant ID, Client Secret from Azure
3. Connect and authorize

### 6.4 Build Sync Workflow

Create a scheduled workflow to sync SharePoint KB to Supabase (see docs for details).

---

## Step 7: Testing

### 7.1 Test Webhook

Use curl or Postman to test the n8n webhook:

```bash
curl -X POST https://your-n8n.app.n8n.cloud/webhook/elevenlabs-handler \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "conversation.started",
    "conversation_id": "test-123",
    "caller_phone": "+15551234567"
  }'
```

### 7.2 Test Tool Calls

```bash
curl -X POST https://your-n8n.app.n8n.cloud/webhook/elevenlabs-handler \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "tool_call",
    "conversation_id": "test-123",
    "tool_name": "search_kb",
    "tool_input": {
      "query": "Fishbowl cannot connect to server",
      "product": "Fishbowl"
    }
  }'
```

### 7.3 Test Full Call

1. Call your Dialpad number
2. Verify:
   - AI answers and greets
   - Identity questions are asked
   - KB search returns results (for known issues)
   - Call is logged in Supabase
   - Email is sent to support@mbacio.com

---

## Troubleshooting

### Call not being answered
- Check Dialpad routing configuration
- Verify SIP trunk is active
- Check ElevenLabs agent status

### Tool calls not working
- Verify webhook URL in ElevenLabs matches n8n
- Check n8n workflow is active
- Review n8n execution logs

### No email notifications
- Check SMTP credentials in n8n
- Verify email node is enabled (not disabled)
- Check spam folder

### KB search not returning results
- Verify kb_embeddings table has data
- Check embedding generation is working
- Lower match_threshold in search function

---

## File Structure

```
claude-n8n-expert/
├── database/
│   └── schema.sql              # Supabase database schema
├── workflows/
│   └── 01-call-handler.json    # Main n8n workflow
├── templates/
│   ├── identity_validation_template.csv
│   ├── email_notification.html
│   └── README.md
├── elevenlabs/
│   └── agent_config.md         # ElevenLabs agent configuration
├── docs/
│   ├── PROJECT_PLAN.md
│   ├── ARCHITECTURE_V2.md
│   └── QUESTIONS.md
├── SETUP_GUIDE.md              # This file
└── README.md
```

---

## Next Steps

After basic setup is working:

1. **Enhance KB Search**: Add more articles, implement proper embedding generation
2. **SharePoint Sync**: Set up automatic KB sync from SharePoint
3. **ConnectWise Integration**: Replace email with direct ticket creation
4. **Analytics Dashboard**: Build reporting views in Supabase
5. **Escalation Flow**: Implement Dialpad presence check for live transfers

---

## Support

For issues with this implementation:
- Check n8n execution logs
- Review Supabase logs in Dashboard > Logs
- Test individual components in isolation

For ElevenLabs issues:
- Check their documentation at docs.elevenlabs.io
- Review conversation logs in ElevenLabs dashboard

For Dialpad issues:
- Contact Dialpad support for SIP configuration help
- Verify your plan supports required features
