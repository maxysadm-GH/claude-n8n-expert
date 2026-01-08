# Fishbowl Inventory Integration Skill

## Activation Triggers
- Fishbowl inventory queries
- Warehouse management integration
- ShipStation + Fishbowl sync
- Pickable order counts

## Context
Fishbowl is the warehouse/inventory management system that tracks:
- Which orders have been imported from ShipStation
- Which orders are pickable (have inventory allocated)
- Pick/pack/ship workflow status

## Integration Pattern with ShipStation

```
Shopify → ShipStation → Fishbowl → Shipping
         (orders)      (picking)   (labels)
```

### Key Metrics

| Metric | Meaning | Source |
|--------|---------|--------|
| **IN FISHBOWL** | Orders imported to Fishbowl for picking | Fishbowl |
| **PICKABLE** | Orders with inventory allocated | Fishbowl |
| **AWAITING SHIPMENT** | ShipStation orders not yet shipped | ShipStation |
| **BACKLOG** | Orders past their dispatch date | CF1 analysis |

## Fishbowl REST API

### Authentication
```json
{
  "Authorization": "Bearer YOUR_FISHBOWL_TOKEN"
}
```

### Key Endpoints

```
# Get Sales Orders
GET /api/sales-orders
Parameters: status, dateFrom, dateTo, pageSize, page

# Get Inventory
GET /api/inventory
Parameters: partNumber, location, warehouse

# Get Pick Status
GET /api/picks
Parameters: status, soNum
```

### Order Status Flow
1. **Entered** - Order imported from ShipStation
2. **Issued** - Inventory allocated (pickable)
3. **In Progress** - Being picked
4. **Fulfilled** - Picked and ready to ship
5. **Shipped** - Back to ShipStation for tracking

## Sync Patterns

### ShipStation → Fishbowl (Order Import)
```
Trigger: New ShipStation order with status "awaiting_shipment"
Action: Create Fishbowl Sales Order
Match on: orderNumber / SO Number
```

### Fishbowl → ShipStation (Ship Confirmation)
```
Trigger: Fishbowl order status = "Shipped"
Action: Update ShipStation with tracking number
```

## EOD Report Integration

The Phoenix EOD Report includes Fishbowl metrics:

```markdown
## 🔄 BATCHING QUEUE
| Metric | Count | Notes |
|--------|-------|-------|
| CF1 EMPTY | XX | ⚠️ Needs Shopify Flow |
| SHIP BY EMPTY | **XX** | 📋 Ready to batch |
| IN FISHBOWL | X,XXX | ✅ Pickable |
| **BACKLOG** | **XX** | 🚨 Priority |
```

## PowerShell Query Pattern

```powershell
# Get Fishbowl order count
$fbHeaders = @{
    "Authorization" = "Bearer $env:FISHBOWL_TOKEN"
    "Content-Type" = "application/json"
}

$fbUrl = "https://your-fishbowl.com/api/sales-orders?status=Issued&pageSize=1"
$response = Invoke-RestMethod -Uri $fbUrl -Headers $fbHeaders
$pickableCount = $response.totalCount
```

## n8n Integration

```json
{
  "name": "Get_Fishbowl_Pickable_Count",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "url": "https://your-fishbowl.com/api/sales-orders",
    "method": "GET",
    "authentication": "genericCredentialType",
    "genericAuthType": "httpHeaderAuth",
    "queryParameters": {
      "status": "Issued",
      "pageSize": "1"
    }
  }
}
```

## Common Issues

### 1. Orders Not Appearing in Fishbowl
- Check ShipStation webhook is configured
- Verify order has valid shipping address
- Check SKU mapping in Fishbowl

### 2. Inventory Allocation Failures
- SKU doesn't exist in Fishbowl
- Insufficient stock
- Location/warehouse mismatch

### 3. Sync Delays
- Fishbowl API can be slow (2-5 seconds per call)
- Batch operations where possible
- Don't poll more than every 5 minutes

## VHC-Specific Notes

For Vosges Haut-Chocolat:
- Fishbowl is the source of truth for inventory
- Orders import from ShipStation Store ID 273669
- Tower SKUs require special handling (multi-component)
- Ice pack requirements determined by weather check, added in Fishbowl
