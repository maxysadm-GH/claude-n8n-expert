# Templates Directory

## Identity Validation Spreadsheet

**File**: `identity_validation_template.csv`

This template is used to maintain a list of known contacts for identity validation during calls. The AI receptionist will cross-reference caller-provided information against this list.

### Columns

| Column | Required | Description | Example |
|--------|----------|-------------|---------|
| `name` | Yes | Full name of the contact | John Smith |
| `email` | Yes* | Email address | john@company.com |
| `phone` | Yes* | Phone number (E.164 format preferred) | +15551234567 |
| `company_name` | No | Company/organization name | Acme Corp |
| `department` | No | Department within company | IT, Sales, etc. |
| `is_vip` | No | VIP flag (true/false) | false |
| `tier` | No | Service tier: standard, premium, enterprise | standard |
| `notes` | No | Internal notes about this contact | Main billing contact |

*At least one of email or phone is required.

### Usage Options

#### Option 1: SharePoint List (Recommended)
1. Create a new SharePoint List in your IT-HelpDesk site
2. Name it "Identity Validation" or "Known Contacts"
3. Add columns matching the template
4. Import the CSV data or add entries manually
5. n8n will sync from this list during calls

#### Option 2: Direct Supabase Import
1. Go to Supabase Dashboard > Table Editor > caller_identity
2. Click "Insert" > "Import from CSV"
3. Upload this template file
4. Map columns to table fields

### Validation Rules

The system matches callers using this priority:
1. **Email match** (35 points) - Exact match on email address
2. **Name match** (40 points) - Exact or partial name match
3. **Phone match** (25 points) - Exact or last-7-digits match

**Thresholds:**
- 80+ points = `validated` - Full match, proceed normally
- 50-79 points = `partial_match` - Ask for clarification
- 20-49 points = `not_found` - Treat as new caller
- <20 points = No match found

### VIP Handling

When `is_vip = true`:
- Priority automatically elevated by one level
- Agent uses more formal language
- Always offers direct escalation option

### Tier Definitions

| Tier | Description | SLA Impact |
|------|-------------|------------|
| `standard` | Regular customers | Normal SLA |
| `premium` | Priority customers | -25% response time |
| `enterprise` | Key accounts | -50% response time, dedicated escalation |

### Syncing with SharePoint

If using SharePoint as the source of truth:
1. Maintain the list in SharePoint
2. n8n workflow `sharepoint-identity-sync.json` runs daily at 2 AM
3. Changes are synced to Supabase `caller_identity` table
4. Real-time lookups query Supabase for speed

### Adding New Contacts

**Via SharePoint:**
- Add a new row to the SharePoint list
- Will sync automatically within 24 hours
- For immediate sync, manually trigger the n8n workflow

**Via Supabase:**
- Insert directly into `caller_identity` table
- Available immediately for validation

**Via n8n (future):**
- Post-call workflow can auto-add unrecognized callers
- Requires approval before adding to validated list
