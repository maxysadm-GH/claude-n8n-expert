# Azure Logic Apps & Power Automate Expert Skill

## Activation Triggers
- Building Azure Logic Apps workflows
- Power Automate flows
- ARM templates for Logic Apps
- JSON workflow definitions
- API integration with Azure services

## Critical JSON Patterns

### Pagination Loop (CRITICAL)
The most common mistake - loops that get stuck on page 1:

```json
{
  "Page_Loop": {
    "type": "Until",
    "expression": "@greater(variables('currentPage'), variables('totalPages'))",
    "limit": { "count": 50, "timeout": "PT2H" },
    "actions": {
      "Get_Data": {
        "type": "Http",
        "inputs": {
          "uri": "https://api.example.com/items?page=@{variables('currentPage')}&pageSize=500",
          "method": "GET"
        }
      },
      "Set_TotalPages": {
        "type": "SetVariable",
        "inputs": { "name": "totalPages", "value": "@body('Get_Data')?['pages']" },
        "runAfter": { "Get_Data": ["Succeeded"] }
      },
      "For_Each": {
        "type": "Foreach",
        "foreach": "@body('Get_Data')?['items']",
        "runAfter": { "Set_TotalPages": ["Succeeded"] }
      },
      "Increment_Page": {
        "type": "IncrementVariable",
        "inputs": { "name": "currentPage", "value": 1 },
        "runAfter": { "For_Each": ["Succeeded", "Failed", "Skipped"] }
      }
    }
  }
}
```

### ⚠️ CRITICAL: runAfter Must Include "Failed"
```json
// WRONG - Flow gets stuck if any item fails:
"runAfter": { "For_Each": ["Succeeded"] }  ❌

// CORRECT - Continues even on failures:
"runAfter": { "For_Each": ["Succeeded", "Failed", "Skipped"] }  ✅
```

### Variable Initialization
```json
{
  "Init_Array": {
    "type": "InitializeVariable",
    "inputs": {
      "variables": [{
        "name": "allItems",
        "type": "array",
        "value": []
      }]
    }
  },
  "Init_Counter": {
    "type": "InitializeVariable",
    "inputs": {
      "variables": [{
        "name": "currentPage",
        "type": "integer",
        "value": 1
      }]
    },
    "runAfter": { "Init_Array": ["Succeeded"] }
  }
}
```

### Append to Array
```json
{
  "Append_Item": {
    "type": "AppendToArrayVariable",
    "inputs": {
      "name": "allItems",
      "value": "@items('For_Each')"
    }
  }
}
```

### HTTP Request with Auth
```json
{
  "HTTP_Request": {
    "type": "Http",
    "inputs": {
      "uri": "https://api.example.com/endpoint",
      "method": "GET",
      "headers": {
        "Authorization": "Basic @{base64(concat(parameters('apiKey'),':',parameters('apiSecret')))}",
        "Content-Type": "application/json"
      }
    },
    "retryPolicy": {
      "type": "exponential",
      "count": 3,
      "interval": "PT20S",
      "maximumInterval": "PT1H"
    }
  }
}
```

### Condition/Switch Pattern
```json
{
  "Condition": {
    "type": "If",
    "expression": {
      "and": [
        { "greater": ["@variables('count')", 0] },
        { "equals": ["@body('Get_Status')?['status']", "active"] }
      ]
    },
    "actions": {
      "True_Branch": { }
    },
    "else": {
      "actions": {
        "False_Branch": { }
      }
    }
  }
}
```

### Parse JSON Schema
```json
{
  "Parse_Response": {
    "type": "ParseJson",
    "inputs": {
      "content": "@body('HTTP_Request')",
      "schema": {
        "type": "object",
        "properties": {
          "items": { "type": "array" },
          "total": { "type": "integer" },
          "page": { "type": "integer" },
          "pages": { "type": "integer" }
        }
      }
    }
  }
}
```

### Compose (Build JSON)
```json
{
  "Compose_Payload": {
    "type": "Compose",
    "inputs": {
      "orderId": "@items('For_Each')?['id']",
      "status": "processed",
      "timestamp": "@utcNow()"
    }
  }
}
```

### Delay/Rate Limiting
```json
{
  "Delay_Between_Calls": {
    "type": "Wait",
    "inputs": {
      "interval": {
        "count": 1,
        "unit": "Second"
      }
    }
  }
}
```

### Teams Notification
```json
{
  "Post_To_Teams": {
    "type": "ApiConnection",
    "inputs": {
      "host": {
        "connection": { "name": "@parameters('$connections')['teams']['connectionId']" }
      },
      "method": "post",
      "path": "/v3/beta/teams/@{encodeURIComponent('team-id')}/channels/@{encodeURIComponent('channel-id')}/messages",
      "body": {
        "body": {
          "content": "<h1>Report Title</h1><p>Content here</p>",
          "contentType": "html"
        }
      }
    }
  }
}
```

### Error Handling Scope
```json
{
  "Try_Scope": {
    "type": "Scope",
    "actions": {
      "Risky_Operation": { }
    }
  },
  "Catch_Scope": {
    "type": "Scope",
    "runAfter": { "Try_Scope": ["Failed"] },
    "actions": {
      "Log_Error": {
        "type": "Compose",
        "inputs": {
          "error": "@result('Try_Scope')",
          "timestamp": "@utcNow()"
        }
      }
    }
  }
}
```

## Expression Functions

### String Functions
```
@concat('Hello ', 'World')
@substring('Hello', 0, 3)  // 'Hel'
@replace('Hello', 'l', 'L')
@toLower('HELLO')
@toUpper('hello')
@trim('  text  ')
@split('a,b,c', ',')
@join(variables('array'), ', ')
```

### Date/Time Functions
```
@utcNow()
@utcNow('yyyy-MM-dd')
@addDays(utcNow(), 7)
@addHours(utcNow(), -24)
@formatDateTime(utcNow(), 'MM-dd-yyyy HH:mm')
@startOfDay(utcNow())
@dayOfWeek(utcNow())
```

### Collection Functions
```
@length(variables('array'))
@first(body('Get_Items')?['items'])
@last(body('Get_Items')?['items'])
@take(variables('array'), 10)
@skip(variables('array'), 5)
@union(array1, array2)
@intersection(array1, array2)
```

### Logical Functions
```
@if(equals(x, y), 'true', 'false')
@and(condition1, condition2)
@or(condition1, condition2)
@not(condition)
@equals(x, y)
@greater(x, y)
@less(x, y)
@empty(variable)
@contains(string, 'search')
```

### Data Functions
```
@json('{"key":"value"}')
@xml('<root>value</root>')
@base64('string')
@base64ToString(base64Value)
@coalesce(null, null, 'default')
@int('123')
@float('123.45')
```

## Common Pitfalls

1. **Pagination stuck on page 1** - Add "Failed" to runAfter
2. **Variables not updating in loop** - Use SetVariable, not InitializeVariable
3. **Array append not working** - Check variable is initialized as array type
4. **HTTP 429 errors** - Add delay between calls
5. **Expression errors** - Use @{} in string context, @ alone in expression context
6. **Null reference** - Use coalesce() or optional chaining with ?[]

## ARM Template Structure
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "logicAppName": { "type": "string" }
  },
  "resources": [{
    "type": "Microsoft.Logic/workflows",
    "apiVersion": "2019-05-01",
    "name": "[parameters('logicAppName')]",
    "location": "[resourceGroup().location]",
    "properties": {
      "definition": {
        "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
        "triggers": { },
        "actions": { }
      }
    }
  }]
}
```
