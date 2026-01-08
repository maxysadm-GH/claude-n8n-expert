# HubSpot CRM API Integration Skill

## Activation Triggers
- HubSpot contact/company queries
- B2B customer segmentation
- CRM sync with n8n
- Deal pipeline analysis

## API Access Methods

| Method | Best For | Recommendation |
|--------|----------|----------------|
| **Private App** | Server-to-server (n8n) | ✅ Use this |
| **OAuth** | User-facing apps | More complex |

### Create Private App
1. HubSpot → Settings → Integrations → Private Apps
2. Create app → Name: "n8n_integration"
3. Select scopes (see below)
4. Copy access token

### Required Scopes
```
crm.objects.contacts.read
crm.objects.contacts.write
crm.objects.companies.read
crm.objects.companies.write
crm.objects.deals.read
crm.lists.read
```

## Rate Limits

| Tier | Limit | Notes |
|------|-------|-------|
| Private App | 100 requests / 10 seconds | Generous |
| Burst | 150 requests / 10 seconds | Brief spikes OK |
| Daily | None | No daily cap |

## Key Endpoints

### Contacts (Individuals)
```
GET /crm/v3/objects/contacts
POST /crm/v3/objects/contacts
PATCH /crm/v3/objects/contacts/{contactId}

# With properties
GET /crm/v3/objects/contacts?properties=email,firstname,lastname,lifecyclestage
```

### Companies (B2B Accounts)
```
GET /crm/v3/objects/companies
POST /crm/v3/objects/companies

# Key properties
GET /crm/v3/objects/companies?properties=name,domain,industry,numberofemployees,annualrevenue
```

### Deals (Pipeline)
```
GET /crm/v3/objects/deals
# Properties: dealname, amount, closedate, dealstage, pipeline
```

### Lists (Pre-built Segments)
```
GET /crm/v3/lists
GET /crm/v3/lists/{listId}/memberships
```

## Search API (Powerful Filtering)

```json
POST /crm/v3/objects/contacts/search
{
  "filterGroups": [{
    "filters": [{
      "propertyName": "lifecyclestage",
      "operator": "EQ",
      "value": "customer"
    }]
  }],
  "properties": ["email", "firstname", "lastname", "createdate"],
  "limit": 100,
  "after": 0
}
```

### Filter Operators
- `EQ` - Equals
- `NEQ` - Not equals
- `LT` / `LTE` - Less than
- `GT` / `GTE` - Greater than
- `CONTAINS_TOKEN` - Contains word
- `HAS_PROPERTY` - Property exists
- `NOT_HAS_PROPERTY` - Property missing

## n8n Native HubSpot Node

n8n has built-in HubSpot support:

```json
{
  "name": "HubSpot_Get_Contacts",
  "type": "n8n-nodes-base.hubspot",
  "parameters": {
    "resource": "contact",
    "operation": "getAll",
    "returnAll": false,
    "limit": 100,
    "additionalFields": {
      "properties": ["email", "firstname", "lastname", "lifecyclestage"]
    }
  },
  "credentials": {
    "hubspotApi": {
      "id": "HUBSPOT_CREDENTIAL_ID",
      "name": "HubSpot Private App"
    }
  }
}
```

## Smart Segmentation Strategy

**Don't pull all contacts to n8n/Airtable!**

Instead:
1. Create "Active Lists" in HubSpot UI (auto-updating)
2. Query list COUNTS from n8n
3. Store counts in Airtable, not individuals

### Example: Segment Counts Only

```json
// Get list membership count
GET /crm/v3/lists/{listId}

Response: {
  "listId": "123",
  "name": "High-Value Customers",
  "processingStatus": "DONE",
  "objectTypeId": "0-1",
  "size": 2847  // ← This is what you store
}
```

## B2B Segmentation Patterns

### By Company Size
```json
{
  "filterGroups": [{
    "filters": [
      { "propertyName": "numberofemployees", "operator": "GTE", "value": "1000" },
      { "propertyName": "annualrevenue", "operator": "GTE", "value": "10000000" }
    ]
  }]
}
```

### By Deal Stage
```json
{
  "filterGroups": [{
    "filters": [
      { "propertyName": "dealstage", "operator": "EQ", "value": "closedwon" }
    ]
  }]
}
```

### By Lifecycle Stage
```
- subscriber
- lead
- marketingqualifiedlead
- salesqualifiedlead
- opportunity
- customer
- evangelist
```

## Associations API

Link contacts to companies:
```
GET /crm/v3/objects/contacts/{contactId}/associations/company
POST /crm/v3/objects/contacts/{contactId}/associations/company/{companyId}/{associationType}
```

## Pagination

```json
// Response includes paging cursor
{
  "results": [...],
  "paging": {
    "next": {
      "after": "100",
      "link": "https://api.hubapi.com/...?after=100"
    }
  }
}
```

In n8n, use "Return All" or loop with `after` parameter.

## VHC B2B Use Cases

| Segment | HubSpot Filter |
|---------|----------------|
| Executive Assistants | `jobtitle CONTAINS "assistant"` |
| HR/People Ops | `jobtitle CONTAINS "HR" OR "people"` |
| Marketing | `jobtitle CONTAINS "marketing"` |
| C-Suite | `jobtitle CONTAINS "CEO" OR "CFO" OR "CMO"` |

## Common Issues

### 1. Rate Limit Hit (429)
- Add 100ms delay between calls
- Use batch endpoints where available

### 2. Property Not Found
- Check property internal name vs label
- Use GET /crm/v3/properties/contacts to list all

### 3. Missing Data
- Check scopes on Private App
- Verify property is set on records

## n8n Credential Setup

1. Create HubSpot Private App (see above)
2. In n8n: Credentials → New → HubSpot API
3. Select "Private App" method
4. Paste access token
