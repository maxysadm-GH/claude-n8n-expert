# Shopify Bulk Operations API Skill

## Activation Triggers
- Exporting large customer lists (100K+)
- Bulk product updates
- Large order exports
- Analytics data extraction

## The Problem with REST API

```
REST API limits:
- 2 requests/second (bucket limit)
- 250 records per page max
- 100K customers = 400+ API calls = 3+ minutes minimum
```

## Solution: Bulk Operations API (GraphQL)

Shopify's Bulk Operations API:
- Export ALL records in one async operation
- No rate limiting during export
- Returns JSONL file for download
- Can export millions of records

## Bulk Export Pattern

### Step 1: Submit Bulk Query

```graphql
mutation {
  bulkOperationRunQuery(
    query: """
    {
      customers(first: 100000) {
        edges {
          node {
            id
            email
            firstName
            lastName
            ordersCount
            totalSpent
            createdAt
            tags
            defaultAddress {
              city
              province
              country
            }
          }
        }
      }
    }
    """
  ) {
    bulkOperation {
      id
      status
    }
    userErrors {
      field
      message
    }
  }
}
```

### Step 2: Poll for Completion

```graphql
query {
  currentBulkOperation {
    id
    status
    errorCode
    createdAt
    completedAt
    objectCount
    fileSize
    url
    partialDataUrl
  }
}
```

**Status Values:**
- `CREATED` - Submitted
- `RUNNING` - Processing
- `COMPLETED` - Ready for download
- `FAILED` - Check errorCode

### Step 3: Download Results

```bash
# Once status = COMPLETED, download the JSONL file
curl -o customers.jsonl "https://storage.shopifycdn.com/bulk-xxxxx.jsonl"
```

### JSONL Format
```jsonl
{"id":"gid://shopify/Customer/123","email":"a@b.com","ordersCount":5,"totalSpent":"450.00"}
{"id":"gid://shopify/Customer/124","email":"c@d.com","ordersCount":2,"totalSpent":"120.00"}
```

## n8n Implementation

### Node 1: Submit Bulk Query
```json
{
  "name": "Submit_Bulk_Export",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "url": "https://{{ $env.SHOPIFY_SHOP }}.myshopify.com/admin/api/2024-01/graphql.json",
    "method": "POST",
    "authentication": "genericCredentialType",
    "headers": {
      "X-Shopify-Access-Token": "{{ $env.SHOPIFY_ADMIN_TOKEN }}",
      "Content-Type": "application/json"
    },
    "body": {
      "query": "mutation { bulkOperationRunQuery(query: \"\"\" { customers... } \"\"\") { bulkOperation { id status } } }"
    }
  }
}
```

### Node 2: Wait Loop
```json
{
  "name": "Wait_For_Completion",
  "type": "n8n-nodes-base.wait",
  "parameters": {
    "amount": 30,
    "unit": "seconds"
  }
}
```

### Node 3: Check Status
```json
{
  "name": "Check_Status",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "url": "https://{{ $env.SHOPIFY_SHOP }}.myshopify.com/admin/api/2024-01/graphql.json",
    "method": "POST",
    "body": {
      "query": "{ currentBulkOperation { status url objectCount } }"
    }
  }
}
```

### Node 4: IF Status Check
```json
{
  "name": "Is_Complete",
  "type": "n8n-nodes-base.if",
  "parameters": {
    "conditions": {
      "string": [{
        "value1": "={{ $json.data.currentBulkOperation.status }}",
        "value2": "COMPLETED",
        "operation": "equals"
      }]
    }
  }
}
```

## Common Export Queries

### Customers with Orders
```graphql
{
  customers(first: 100000, query: "orders_count:>0") {
    edges {
      node {
        id email ordersCount totalSpent
        lastOrder { createdAt totalPriceSet { shopMoney { amount } } }
      }
    }
  }
}
```

### Orders with Line Items
```graphql
{
  orders(first: 100000, query: "created_at:>=2024-01-01") {
    edges {
      node {
        id name createdAt
        totalPriceSet { shopMoney { amount } }
        lineItems(first: 50) {
          edges { node { sku quantity title } }
        }
        shippingAddress { city province country }
      }
    }
  }
}
```

### Products with Inventory
```graphql
{
  products(first: 50000) {
    edges {
      node {
        id title handle
        variants(first: 100) {
          edges {
            node {
              sku
              inventoryQuantity
              price
            }
          }
        }
      }
    }
  }
}
```

## VHC-Specific Credentials

```
Store URL: vosgeschocolate.myshopify.com
Admin API Token: [REDACTED - Get from password manager or .env]
Storefront Token: [REDACTED - Get from password manager or .env]

DEV Store: vosges-dev-site-2024.myshopify.com
DEV Token: [REDACTED - Get from password manager or .env]
```

## Processing JSONL in Python

```python
import json

customers = []
with open('customers.jsonl', 'r') as f:
    for line in f:
        customer = json.loads(line)
        customers.append(customer)

# Segment analysis
high_value = [c for c in customers if float(c.get('totalSpent', 0)) > 500]
print(f"High-value customers: {len(high_value)}")
```

## Alternative: Manual CSV Export

For quick one-time exports:
1. Shopify Admin → Customers → Export
2. Select "All customers" or filtered
3. Download CSV
4. Process locally

**When to use CSV vs Bulk API:**
- One-time analysis → CSV
- Recurring sync → Bulk API
- Real-time queries → REST API with segments
