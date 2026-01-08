# ShipStation & VHC Integration Skill

## Overview
This skill contains hard-won lessons learned from months of ShipStation API integration work for Vosges Haut-Chocolat (VHC). Use this to avoid re-learning painful API quirks and to maintain consistency across Logic Apps, Power Automate, and PowerShell scripts.

---

## CREDENTIALS REFERENCE

### ShipStation PROD (Vosges Main Account)
```
API Key: ${SHIPSTATION_API_KEY}
API Secret: ${SHIPSTATION_API_SECRET}
Base64 Auth: ${SHIPSTATION_BASE64_AUTH}
x-partner Key: ${SHIPSTATION_PARTNER_KEY}
```

### ShipStation DEV/TEST
```
API Key: ${SHIPSTATION_DEV_API_KEY}
API Secret: ${SHIPSTATION_DEV_API_SECRET}
```

### ShipStation Store IDs
| Store ID | Name | Use |
|----------|------|-----|
| 273669 | Shopify Store | **PROD - Primary VHC orders** |
| 219870 | Special BD | BD/Corporate orders |
| 2971165 | Manual Orders | Testing/manual entry |
| 2973455 | DEV Store | Development testing |

### Shopify PROD
```
Store URL: vosgeschocolate.myshopify.com
Admin API Token: ${SHOPIFY_ADMIN_TOKEN}
Storefront Token: ${SHOPIFY_STOREFRONT_TOKEN}
```

### Shopify DEV
```
Store URL: vosges-dev-site-2024.myshopify.com
Admin API Token: ${SHOPIFY_DEV_TOKEN}
```

### Supabase
```
URL: https://${SUPABASE_PROJECT_REF}.supabase.co
Anon Key: ${SUPABASE_ANON_KEY}
```

### Weather API
```
Key: ${WEATHER_API_KEY}
```

---

## SHIPSTATION API - CRITICAL LESSONS LEARNED

### ⚠️ SORTING DOES NOT WORK AS EXPECTED

**BROKEN:** `sortBy=OrderDate&sortDir=DESC` - Returns orders in unpredictable order
**BROKEN:** `sortBy=CreateDate&sortDir=DESC` - Same issue
**BROKEN:** `sortBy=OrderNumber` - Not a valid sort field

**ONLY VALID:** `sortBy=ModifyDate` - The ONLY sortBy that actually works consistently

```
# DON'T USE:
/orders?sortBy=OrderDate&sortDir=DESC  ❌

# USE:
/orders?sortBy=ModifyDate&sortDir=DESC  ✅
```

### ⚠️ DATE FILTERS ON /orders ARE BROKEN
The `shipDateStart` and `shipDateEnd` parameters return ALL orders, not filtered results.

```
# BROKEN - Returns all orders, not just Dec 26:
/orders?orderStatus=shipped&shipDateStart=2025-12-26&shipDateEnd=2025-12-26  ❌

# SOLUTION - Use /shipments endpoint for shipped orders:
/shipments?shipDateStart=2025-12-26&shipDateEnd=2025-12-26  ✅
```

### ⚠️ PAGINATION RULES
- **Max pageSize:** 500 (hard limit)
- **Default pageSize:** 100
- **Always paginate:** Large order sets require looping through all pages
- **Response includes:** `{ "orders": [...], "total": N, "page": X, "pages": Y }`

```json
// Pagination loop pattern for Logic Apps
"Until_All_Pages": {
    "type": "Until",
    "expression": "@greater(variables('currentPage'), variables('totalPages'))",
    "limit": { "count": 50, "timeout": "PT2H" },
    "actions": {
        "Get_Orders": {
            "uri": "https://ssapi.shipstation.com/orders?pageSize=500&page=@{variables('currentPage')}"
        },
        "Increment_Page": {
            "runAfter": { "For_each": ["Succeeded", "Failed"] }  // CRITICAL: Include Failed!
        }
    }
}
```

### ⚠️ RATE LIMITING
| Scenario | Rate Limit |
|----------|------------|
| Without x-partner header | 40 RPM |
| With x-partner header | 100 RPM |

**Always include x-partner header:**
```json
"headers": {
    "Authorization": "Basic ${SHIPSTATION_BASE64_AUTH}",
    "x-partner": "${SHIPSTATION_PARTNER_KEY}"
}
```

**PowerShell with rate limit handling:**
```powershell
$headers = @{ 
    "Authorization" = "Basic $auth"
    "x-partner" = "${SHIPSTATION_PARTNER_KEY}"
}
Start-Sleep -Milliseconds 650  # Safe for 100 RPM
```

---

## AZURE LOGIC APP PATTERNS

### Proper Pagination Loop Structure

```json
{
    "Init_CurrentPage": {
        "type": "InitializeVariable",
        "inputs": { "variables": [{ "name": "currentPage", "type": "integer", "value": 1 }] }
    },
    "Init_TotalPages": {
        "type": "InitializeVariable", 
        "inputs": { "variables": [{ "name": "totalPages", "type": "integer", "value": 1 }] },
        "runAfter": { "Init_CurrentPage": ["Succeeded"] }
    },
    "Page_Loop": {
        "type": "Until",
        "expression": "@greater(variables('currentPage'), variables('totalPages'))",
        "limit": { "count": 50, "timeout": "PT2H" },
        "actions": {
            "Get_Orders": {
                "type": "Http",
                "inputs": {
                    "uri": "https://ssapi.shipstation.com/orders?orderStatus=awaiting_shipment&storeId=273669&pageSize=500&page=@{variables('currentPage')}",
                    "method": "GET",
                    "headers": {
                        "Authorization": "Basic ${SHIPSTATION_BASE64_AUTH}",
                        "x-partner": "${SHIPSTATION_PARTNER_KEY}"
                    }
                }
            },
            "Set_TotalPages": {
                "type": "SetVariable",
                "inputs": { "name": "totalPages", "value": "@body('Get_Orders')?['pages']" },
                "runAfter": { "Get_Orders": ["Succeeded"] }
            },
            "For_Each": {
                "type": "Foreach",
                "foreach": "@body('Get_Orders')?['orders']",
                "runAfter": { "Set_TotalPages": ["Succeeded"] }
            },
            "Increment_Page": {
                "type": "IncrementVariable",
                "inputs": { "name": "currentPage", "value": 1 },
                "runAfter": { "For_Each": ["Succeeded", "Failed", "Skipped"] }
            }
        },
        "runAfter": { "Init_TotalPages": ["Succeeded"] }
    }
}
```

### ⚠️ CRITICAL: runAfter Must Include "Failed"
If `Increment_Page` only runs on "Succeeded", ANY order failure stops pagination forever:
```json
// WRONG - Flow gets stuck on page 1 forever if any order fails:
"runAfter": { "For_Each": ["Succeeded"] }  ❌

// CORRECT - Continues to next page even if some orders fail:
"runAfter": { "For_Each": ["Succeeded", "Failed", "Skipped"] }  ✅
```

### Parse JSON Schema for Orders
```json
{
    "type": "object",
    "properties": {
        "orders": { "type": "array" },
        "total": { "type": "integer" },
        "page": { "type": "integer" },
        "pages": { "type": "integer" }
    }
}
```

---

## CUSTOM FIELDS MAPPING

| Field | Use | Format |
|-------|-----|--------|
| customField1 | Dispatch Date (from Shopify tags) | `MM-DD-YYYY` |
| customField2 | Box Code (from ShipperHQ) | `BOX \| 14x14x6 \| ICE - 140` |
| customField3 | Weather Check Result | `ICE-120 \| 10/27 53.6F` or `NO ICE \| CHI 72F` |

### Updating Custom Fields
```json
// Use /orders/createorder endpoint (works for updates too)
POST https://ssapi.shipstation.com/orders/createorder
{
    "orderId": 123456789,
    "advancedOptions": {
        "customField1": "12-28-2025",
        "customField2": "BOX | 14x14x6",
        "customField3": "ICE-140 | 12/28 45.2F"
    }
}
```

---

## POWERSHELL SCRIPT PATTERNS

### Standard API Setup

```powershell
# === STANDARD SHIPSTATION API SETUP ===
$apiKey = $env:SHIPSTATION_API_KEY  # Or hardcode for scripts
$apiSecret = $env:SHIPSTATION_API_SECRET
$xPartnerKey = "${SHIPSTATION_PARTNER_KEY}"

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${apiKey}:${apiSecret}"))
$headers = @{ 
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
    "x-partner" = $xPartnerKey
}
$baseUrl = "https://ssapi.shipstation.com"
```

### Pagination Loop Pattern
```powershell
$allOrders = @()
$page = 1

do {
    $url = "$baseUrl/orders?orderStatus=awaiting_shipment&pageSize=500&page=$page"
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers
        $allOrders += $response.orders
        Write-Host "Page $page: $($response.orders.Count) orders" -ForegroundColor Gray
        $hasMore = $response.orders.Count -eq 500
        $page++
        Start-Sleep -Milliseconds 650  # Respect 100 RPM
    } catch {
        if ($_.Exception.Response.StatusCode -eq 429) {
            Write-Host "Rate limited, waiting 30s..." -ForegroundColor Yellow
            Start-Sleep -Seconds 30
        } else { throw }
    }
} while ($hasMore)
```

### Getting Shipped Orders (Use /shipments, NOT /orders)
```powershell
# For accurate shipped counts by date:
$url = "$baseUrl/shipments?shipDateStart=2025-12-26&shipDateEnd=2025-12-26&pageSize=500&page=1"
$shipments = Invoke-RestMethod -Uri $url -Headers $headers
Write-Host "Shipped on 12/26: $($shipments.total)"
```

---

## COMMON PITFALLS & SOLUTIONS

### 1. Orders Not Found After Import
**Problem:** Orders exist in Shopify but search returns empty
**Cause:** Wrong storeId or searching before sync completes
**Solution:** Always include `storeId=273669` for Shopify orders

### 2. CF1 Empty Despite Mapping
**Problem:** Shopify tags mapped but CF1 stays empty
**Cause:** Mapping only applies to NEW orders, not existing
**Solution:** Build Logic App to backfill CF1 from Shopify tags

### 3. Logic App Stuck on Page 1
**Problem:** Loop processes same 500 orders repeatedly
**Cause:** `Increment_Page` only runs on "Succeeded"
**Solution:** Add "Failed" and "Skipped" to runAfter

### 4. Wrong Order Counts
**Problem:** /orders with date filter returns all orders
**Cause:** shipDateStart/End filters are broken on /orders
**Solution:** Use /shipments endpoint for shipped order counts

### 5. Rate Limiting (429 Errors)
**Problem:** Frequent 429 responses
**Cause:** Missing x-partner header (stuck at 40 RPM)
**Solution:** Add `x-partner: ${SHIPSTATION_PARTNER_KEY}`

### 6. Sort Not Working
**Problem:** Orders not in expected order
**Cause:** Only `sortBy=ModifyDate` actually works
**Solution:** Don't rely on sort; filter client-side if needed

---

## EOD REPORT STRUCTURE

### Required Sections
1. **Shipped Today** - Use /shipments endpoint
2. **Awaiting by Store** - Shopify (273669) + BD (219870)
3. **72-Hour Forecast** - Group by CF1 dispatch date
4. **Tower Breakdown** - SKUs containing "TOW" or "TOWER"
5. **Top 20 SKUs** - Per day in forecast window
6. **Batching Queue** - CF1 empty, Ship By empty counts
7. **Backlog** - Orders past their dispatch date

### Script Location
`C:\Scripts\Phoenix_EOD_v3.ps1`

---

## WEATHER CHECK ICE PACK LOGIC

### Ice Pack Determination

| Condition | Ice Pack | CF3 Format |
|-----------|----------|------------|
| Chicago local (<80°F) | None | `NO ICE \| CHI 72F` |
| Route max >85°F | ICE-160 (4 packs) | `ICE-160 \| 12/28 87.2F` |
| Route max >75°F | ICE-140 (3 packs) | `ICE-140 \| 12/28 78.5F` |
| Route max >65°F | ICE-120 (2 packs) | `ICE-120 \| 12/28 68.1F` |
| Route max ≤65°F | None | `NO ICE \| 12/28 62.3F` |
| API failure | N/A | `WC-FAILED` |

### Distribution Hubs
- Chicago (CHI) - Primary
- Memphis (MEM)
- Miami (MIA)
- Fort Worth (DFW)
- Oakland (OAK)

---

## PACKING SLIP TEMPLATE

**Current Version:** v3.34

**Barcode Positioning:**
```css
padding-left: 170px;
padding-top: 1.15in;
padding-right: 20px;
```

---

## BOX CODE 2.0 (ShipperHQ Integration)

### CF2 Output Format
```
BOX | 14x14x6 | ICE - 140
```
Or when no data from ShipperHQ:
```
CUSTOM (ND)
```

### ShipperHQ Insights API
Query box dimensions after order import, write to CF2.

---

## QUICK REFERENCE

### API Endpoints
| Endpoint | Use |
|----------|-----|
| GET /orders | Fetch orders (paginate!) |
| GET /shipments | Shipped orders with working date filters |
| POST /orders/createorder | Create OR update orders |
| GET /stores | List connected stores |

### Store ID Quick Reference
- **273669** = Shopify PROD (VHC orders)
- **219870** = Special BD

### Headers Template (Logic Apps)
```json
{
    "Authorization": "Basic ${SHIPSTATION_BASE64_AUTH}",
    "x-partner": "${SHIPSTATION_PARTNER_KEY}",
    "Content-Type": "application/json"
}
```

### Headers Template (PowerShell)
```powershell
$headers = @{
    "Authorization" = "Basic ${SHIPSTATION_BASE64_AUTH}"
    "x-partner" = "${SHIPSTATION_PARTNER_KEY}"
    "Content-Type" = "application/json"
}
```

---

## THINGS THAT DON'T WORK (DON'T WASTE TIME)

1. ❌ `sortBy=OrderDate` - Doesn't sort properly
2. ❌ `sortBy=CreateDate` - Doesn't sort properly  
3. ❌ `sortBy=OrderNumber` - Invalid field
4. ❌ `/orders?shipDateStart=X` - Returns all orders
5. ❌ Updating shipped/cancelled orders - API rejects
6. ❌ pageSize > 500 - Hard limit

## THINGS THAT WORK

1. ✅ `sortBy=ModifyDate` - Only working sort
2. ✅ `/shipments?shipDateStart=X` - Accurate date filtering
3. ✅ `x-partner` header - 100 RPM vs 40 RPM
4. ✅ pageSize=500 - Max efficiency
5. ✅ POST /orders/createorder - Works for updates too
6. ✅ `storeId=273669` filter - Shopify orders only

---

*Last Updated: December 2025*
*Source: Compiled from months of VHC integration work*


---

## REPORTING PATTERNS

### EOD Report Structure (Teams-Ready Markdown)
The Phoenix EOD Report follows this exact structure for Teams posting:

```markdown
# 📊 PHOENIX EOD REPORT - [Day, Month Date, Year]
### Shopify Store + Special BD

---

## ✅ TODAY'S PERFORMANCE
| Metric | Count |
|--------|-------|
| 🎉 **Shipped Today** | **X,XXX** |
| 📦 **Awaiting Shipment** | X,XXX |

### Service Breakdown (Today)
| Service | Count |
|---------|-------|
| FedEx Home Delivery | XXX |
| FedEx 2Day | XXX |
| FedEx Ground | XX |
| Standard Overnight | XX |

---

## 🔄 BATCHING QUEUE
| Metric | Count | Notes |
|--------|-------|-------|
| CF1 EMPTY | XX | ⚠️ Needs Shopify Flow |
| SHIP BY EMPTY (Shopify only) | **XX** | 📋 Ready to batch |
| IN FISHBOWL | X,XXX | ✅ Pickable |
| **BACKLOG** | **XX** | 🚨 Priority |

---

## 🚨 BACKLOG BY DATE
| Date | Orders |
|------|--------|
| 12-XX | X |
| **TOTAL** | **XX** |

---

## 📅 72-HOUR FORECAST (Shopify + BD)
| Day | Total | HD | 2Day | GR | ON | Intl | Towers |
|-----|-------|----|----|----|----|------|--------|
| [Day] 🔥 | **XXX** | XXX | XXX | XX | XX | X | XX |
| [Day] | XXX | XXX | XXX | XX | XX | X | XX |
| [Day] | XXX | XXX | XXX | XX | XX | X | XX |
| **3-Day Total** | **X,XXX** | - | - | - | - | - | **XXX** |

---

## 🗼 TOWER FORECAST BY SKU
| SKU | Product | Day1 | Day2 | Day3 | TOTAL |
|-----|---------|------|------|------|-------|
| GS-TOW-GRA | Grande Gift Tower | XX | X | X | **XX** |
| GS-TOW-COM | Comfort Food Tower | XX | X | X | **XX** |
| GS-TOW-WILD | Wild Chocolate Tower | XX | X | X | **XX** |
| GS-TOWER-GRA-H25 | Grande Holiday Tower | XX | X | X | **XX** |
| GS-TOW-WREATH | Enchanted Tower | XX | X | X | **XX** |
| GS-TOW-PET | Petite Gift Tower | XX | X | X | **XX** |
| TC-TOW-HOL-PET | Midnight Magic | XX | X | X | **XX** |
| GS-TOW-DALMORE | Dalmore x Vosges | XX | X | X | **XX** |
| **DAILY TOTALS** | | **XX** | **XX** | **XX** | **XXX** |

---

## 📦 TOP 20 SKUs - [Day] (XXX orders)
| # | SKU | Qty | Ord | Product |
|---|-----|-----|-----|---------|
| 1 | TC-EXO-016 | XXX | XX | Exotic Truffle Collection 16pc |
...

---

## 📈 KEY TAKEAWAYS
| Metric | Result |
|--------|--------|
| 🎉 **Shipped Today** | **X,XXX orders** |
| 📉 **Backlog** | **XX** orders |
| 🔥 **Tomorrow Focus** | XXX orders + XX towers |
| 🗼 **Tower Priority** | [Top 3 towers] |

---
*Report generated: [timestamp] | Script: C:\Scripts\Phoenix_EOD_v3.ps1*
```

### Tower SKU Patterns
```powershell
$TOWER_SKUS = @(
    "GS-TOW-GRA",      # Grande Gift Tower
    "GS-TOW-COM",      # Comfort Food Tower
    "GS-TOW-WILD",     # Wild Chocolate Tower
    "GS-TOWER-GRA-H25",# Grande Holiday Tower
    "GS-TOW-WREATH",   # Enchanted Tower of Treats
    "GS-TOW-PET",      # Petite Gift Tower
    "TC-TOW-HOL-PET",  # Midnight Magic Truffle Tower
    "GS-TOW-DALMORE"   # Dalmore x Vosges Tower
)
```


### Script Locations
| Script | Purpose | Location |
|--------|---------|----------|
| Phoenix EOD v3.1 | Full EOD report | `C:\Scripts\Phoenix_EOD_v3.ps1` |
| 72-Hour Forecast | Quick forecast | `C:\Temp\ss_backlog_forecast_v3.ps1` |
| Top SKUs Report | SKU analysis | `C:\Temp\ss_top_skus_report.ps1` |

### Running EOD Report
```powershell
powershell -ExecutionPolicy Bypass -File "C:\Scripts\Phoenix_EOD_v3.ps1"

# With Teams posting (requires webhook configured)
powershell -ExecutionPolicy Bypass -File "C:\Scripts\Phoenix_EOD_v3.ps1" -PostToTeams
```

---

## EXECUTIVE HTML REPORT STRUCTURE

### Q4 Executive Report Template
File: `C:\Temp\ShipStation Reports\Q4_Executive_Report_v3.html`

**Sections:**
1. **Daily Performance - TODAY**
   - Cards: Shipped Today, Avg/Hour (12hr), Peak Hour Vol, Peak Time
   - Hourly Breakdown grid (6AM-6PM)

2. **Key Metrics at a Glance**
   - YOY comparison: 2023, 2024, 2025
   - Q4 totals with percentage changes

3. **Weekly Performance (Q4)**
   - Week-by-week comparison across 3 years
   - W40-W52 breakdown

4. **Day of Week Pattern & Staffing Guide**
   - Based on past 5 weeks average
   - Avg Volume, Avg/Hour, Peak Capacity (+30%)

5. **Monthly Breakdown**
   - Oct, Nov, Dec with YOY
   - December forecast based on remaining shipping days

6. **Service Mix**
   - All FedEx services breakdown
   - Tier distribution: Ground/Home, 2Day Express, Air/Overnight, International

7. **FedEx OneRate Analysis**
   - Savings missed, eligible shipments, avg savings/pkg

8. **Store Breakdown**
   - Shopify Store, Special BD, Fishbowl, etc.

9. **Key Takeaways** (10 Points)
10. **Recommendations for Improvement**
11. **Appendix: Data Sources & Methodology**

### HTML Styling (Vosges Brand Colors)
```css
/* Header gradient */
background: linear-gradient(135deg, #4a1c40, #722f5a);

/* Theme colors */
--primary: #4a1c40;
--accent: #722f5a;
--positive: #28a745;
--negative: #dc3545;
```

### Report Cards Pattern
```html
<div class="cards">
  <div class="card">
    <div class="val">2,611</div>
    <div class="lbl">Shipped Today</div>
  </div>
</div>
```

---

## FORECAST CALCULATION LOGIC

### 72-Hour Forecast
```powershell
# Get next 3 business days (skip weekends for retail)
$forecastDays = @()
$checkDate = (Get-Date).Date.AddDays(1)
while ($forecastDays.Count -lt 3) {
    # Include all days for holiday season (weekends may have shipments)
    $forecastDays += $checkDate
    $checkDate = $checkDate.AddDays(1)
}

# Group orders by CF1 dispatch date
$ordersByDate = $allOrders | Group-Object { 
    $_.advancedOptions.customField1 
} | Where-Object { $_.Name -match '^\d{2}-\d{2}-\d{4}$' }
```

### Backlog Calculation
```powershell
$today = (Get-Date).Date
$todayStr = $today.ToString("MM-dd-yyyy")

$backlog = $allOrders | Where-Object {
    $cf1 = $_.advancedOptions.customField1
    if ($cf1 -match '^\d{2}-\d{2}-\d{4}$') {
        $dispatchDate = [DateTime]::ParseExact($cf1, "MM-dd-yyyy", $null)
        return $dispatchDate.Date -lt $today
    }
    return $false
}
```

### Tower Detection
```powershell
$isTower = $item.sku -match 'TOW|TOWER'
# Or explicit list:
$isTower = $TOWER_SKUS -contains $item.sku
```

---

## SHIPPED COUNT - CRITICAL FIX

### ⚠️ DO NOT USE /orders FOR SHIPPED COUNTS
```powershell
# BROKEN - Returns wrong data:
/orders?orderStatus=shipped&shipDateStart=2025-12-26&shipDateEnd=2025-12-26  ❌

# CORRECT - Use /shipments endpoint:
$url = "$baseUrl/shipments?shipDateStart=$todayStr&shipDateEnd=$todayStr&pageSize=500"
$shipments = Invoke-RestMethod -Uri $url -Headers $headers
$shippedCount = $shipments.total  ✅
```

### Multi-Store Shipped Counts
```powershell
# Shopify Store (273669)
$shopifyUrl = "$baseUrl/shipments?storeId=273669&shipDateStart=$date&shipDateEnd=$date&pageSize=1"
$shopifyShipped = (Invoke-RestMethod -Uri $shopifyUrl -Headers $headers).total

# Special BD (219870)  
$bdUrl = "$baseUrl/shipments?storeId=219870&shipDateStart=$date&shipDateEnd=$date&pageSize=1"
$bdShipped = (Invoke-RestMethod -Uri $bdUrl -Headers $headers).total

$totalShipped = $shopifyShipped + $bdShipped
```

---

## SERVICE CODE MAPPING

| Service Code | Display Name | Category |
|--------------|--------------|----------|
| fedex_home_delivery | FedEx Home Delivery® | Ground/Home |
| fedex_ground | FedEx Ground® | Ground/Home |
| fedex_2_day | FedEx 2Day® | 2Day Express |
| fedex_standard_overnight | FedEx Standard Overnight® | Air/Overnight |
| fedex_priority_overnight | FedEx Priority Overnight® | Air/Overnight |
| fedex_international_economy | FedEx International Economy® | International |
| fedex_international_priority | FedEx International Priority® | International |

---

## STAFFING METRICS (From Executive Report)

### Day of Week Averages (Based on 5-Week Rolling)
| Day | Avg Volume | Avg/Hour (12hr) | Peak Capacity (+30%) | % of Week |
|-----|------------|-----------------|----------------------|-----------|
| Monday | 1,868 | 155/hr | 201/hr | 24.3% |
| Tuesday | 1,637 | 136/hr | 176/hr | 21.3% |
| Wednesday | 1,391 | 115/hr | 149/hr | 18.1% |
| Thursday | 953 | 79/hr | 102/hr | 12.4% |
| Friday | 683 | 56/hr | 72/hr | 8.9% |
| Saturday | 1,156 | 96/hr | 124/hr | 15.0% |

**Key Insight:** Monday-Tuesday = peak (45% of weekly volume), Thursday-Friday = light

---

*Last Updated: December 2025*
