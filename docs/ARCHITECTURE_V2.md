# Virtual Receptionist - Simplified Architecture v2

## Core Principle: Layers, Not Complexity

ElevenLabs Conversational AI is the brain. n8n is the body (actions). Supabase is the memory.

---

## The Five Layers

### Layer 1: Never Lose a Call
**Goal**: Every call is captured, logged, and tracked.

```
Incoming Call → Dialpad → ElevenLabs Agent → n8n logs to Supabase
```

- Even if call drops, we have: timestamp, caller ID, partial transcript
- Webhook fires on call start, end, and key events
- Supabase `call_log` table captures everything

---

### Layer 2: AI-Driven Intent + Identity
**Goal**: Remove IVR. AI understands what they need and who they are.

ElevenLabs Agent handles the conversation:
```
"Thank you for calling MBACIO, my name is [Agent]. How can I help you today?"

→ Caller explains issue

"I understand you're having trouble with [X]. Before I help, let me verify a few details.
 Can I get your name?"

→ [Name captured]

"And the best email to reach you?"

→ [Email captured]

"And a callback number in case we get disconnected?"

→ [Callback captured]
```

**No IVR menu. AI infers intent from natural conversation.**

Intent categories (detected by AI):
- Support (technical issues)
- Sales (pricing, demos, new service)
- Billing/Payments (invoices, payment issues)
- General inquiry

---

### Layer 3: Log the Request
**Goal**: Create ticket, notify team.

n8n workflow triggered by ElevenLabs webhook:

```
ElevenLabs webhook (call summary)
        │
        ├──→ ConnectWise API: Create ticket
        │         • Caller name, email, phone
        │         • Issue summary (AI-generated)
        │         • Call transcript
        │         • Timestamp
        │
        └──→ Email to support@mbacio.com
                  • Ticket confirmation
                  • Call recording link (if available)
```

---

### Layer 4: Priority & SLA
**Goal**: Auto-classify urgency based on issue type and impact.

Priority Logic (in n8n):

| Trigger Words/Patterns | Impact | Priority |
|------------------------|--------|----------|
| "down", "not working", "all users affected" | Critical | P1 - Urgent |
| "can't login", "error", "one user" | High | P2 - High |
| "slow", "question about", "how do I" | Medium | P3 - Normal |
| "when I get a chance", "not urgent" | Low | P4 - Low |

SLA Response Times:
- P1: 15 min response
- P2: 1 hour response
- P3: 4 hour response
- P4: 24 hour response

ConnectWise ticket updated with priority automatically.

---

### Layer 5: First Call Resolution (FCR)
**Goal**: Solve common issues without human escalation.

**Your Example Flow:**
```
Caller: "I can't login to Fishbowl"

Agent: "I'm sorry to hear that. Are you seeing any error message?"

Caller: "Yes, it says the server cannot be reached"

Agent: "Please hit OK on that screen. Now, can you expand the login
        screen by clicking the DETAILS button and tell me the
        Server Address and Port you see?"

        [n8n webhook: search KB for "Fishbowl server cannot be reached"]
        [Returns: Common issue - wrong port, correct port is XXXX]

Caller: "It shows server.company.com and port 1234"

Agent: "I see the issue - that port is incorrect. Please change
        the port to [CORRECT_PORT] and try logging in again."

Caller: "It works!"

Agent: "I'm glad to hear that! Is there anything else I can help
        you with today?"

Caller: "No, that's it."

Agent: "Great [Name]! You'll receive a ticket confirmation at
        [email] that you can respond to if you need any further
        assistance. Have a great day!"
```

**Escalation Triggers:**
- Issue requires admin/elevated access
- Caller asks for a human
- AI confidence is low
- Issue not in KB
- 3+ failed resolution attempts

---

## Simplified Tech Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                        DIALPAD (PRO)                             │
│                    SIP Trunk → ElevenLabs                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 ELEVENLABS CONVERSATIONAL AI                     │
│  • Real-time voice conversation                                  │
│  • Intent detection                                              │
│  • Identity capture                                              │
│  • Tool calls via webhooks → n8n                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         N8N WORKFLOWS                            │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ KB Search   │  │ Log Call    │  │ Create      │              │
│  │ (Supabase   │  │ (Supabase)  │  │ Ticket      │              │
│  │  pgvector)  │  │             │  │ (ConnectWise)│             │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ Send Email  │  │ Set Priority│  │ Check       │              │
│  │ Notification│  │ (SLA Logic) │  │ Presence    │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         SUPABASE                                 │
│                                                                  │
│  Tables:                      Vector Store:                      │
│  • call_log                   • kb_embeddings (pgvector)         │
│  • caller_identity            • SharePoint content indexed       │
│  • ticket_mapping                                                │
│  • conversation_history                                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      EXTERNAL SYSTEMS                            │
│                                                                  │
│  • ConnectWise (Ticket creation/update)                         │
│  • SharePoint (KB source - read only)                           │
│  • Email (SMTP/SendGrid for notifications)                      │
│  • Dialpad Presence API (for escalation routing)                │
└─────────────────────────────────────────────────────────────────┘
```

---

## What We're NOT Using Anymore

| Original | Replaced With | Why |
|----------|---------------|-----|
| Qdrant | Supabase pgvector | One less service, already using Supabase |
| Complex IVR routing | ElevenLabs AI intent detection | Simpler, better UX |
| Multiple ElevenLabs agents | Single agent with context | One agent handles all intents |
| Airtable | Supabase | Consolidation |
| Google Drive | SharePoint | Your existing KB location |

---

## n8n Workflow Structure (Simplified)

```
/workflows
├── 01-call-handler.json           # Main webhook receiver from ElevenLabs
│                                   # Routes to sub-workflows based on action
│
├── 02-kb-search.json              # Supabase pgvector semantic search
│                                   # Returns relevant KB articles
│
├── 03-ticket-create.json          # ConnectWise API integration
│                                   # Creates ticket with caller info + summary
│
├── 04-priority-sla.json           # Analyzes issue, sets priority
│                                   # Updates ConnectWise ticket
│
├── 05-email-notify.json           # Sends confirmation to support@mbacio.com
│                                   # Sends summary to caller email
│
├── 06-presence-check.json         # Dialpad API - check if agent available
│                                   # For escalation routing
│
└── 07-call-logger.json            # Logs everything to Supabase
                                    # Call metadata, transcript, outcome
```

---

## Supabase Schema

```sql
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Call log table
CREATE TABLE call_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dialpad_call_id TEXT,
    elevenlabs_conversation_id TEXT,
    caller_phone TEXT,
    caller_name TEXT,
    caller_email TEXT,
    callback_number TEXT,
    intent TEXT,  -- 'support', 'sales', 'billing', 'general'
    summary TEXT,
    transcript JSONB,
    priority TEXT,  -- 'P1', 'P2', 'P3', 'P4'
    connectwise_ticket_id TEXT,
    outcome TEXT,  -- 'resolved', 'escalated', 'callback_scheduled', 'dropped'
    duration_seconds INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Knowledge base embeddings
CREATE TABLE kb_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source TEXT,  -- 'sharepoint', 'manual'
    source_url TEXT,
    title TEXT,
    content TEXT,
    embedding vector(1536),  -- OpenAI embedding dimension
    category TEXT,  -- 'fishbowl', 'network', 'email', etc.
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for vector similarity search
CREATE INDEX ON kb_embeddings USING ivfflat (embedding vector_cosine_ops);
```

---

## Implementation Order

### Phase 1: Foundation (Today)
1. ✅ Set up Supabase tables
2. ✅ Create n8n webhook endpoints
3. ✅ Basic call logging workflow

### Phase 2: ElevenLabs Integration
1. Configure ElevenLabs agent with system prompt
2. Set up SIP trunk in Dialpad
3. Connect agent → n8n webhooks
4. Test end-to-end call flow

### Phase 3: KB & Resolution
1. Index SharePoint content to Supabase pgvector
2. Build KB search workflow
3. Integrate search results into agent responses

### Phase 4: Ticketing & Notifications
1. ConnectWise API integration
2. Priority/SLA logic
3. Email notifications

### Phase 5: Escalation
1. Dialpad presence check
2. Transfer logic
3. Fallback handling

---

## Questions Resolved

| Question | Answer |
|----------|--------|
| Database | Supabase |
| Vector DB | Supabase pgvector (no Qdrant) |
| KB Storage | SharePoint |
| Dialpad Plan | PRO (confirmed) |
| Email | support@mbacio.com |
| Ticketing | ConnectWise API |

## Still Need

1. **ConnectWise API credentials** - Do you have API access?
2. **Supabase project URL/key** - You mentioned I have access?
3. **SharePoint site URL** - For KB indexing
4. **Company name** - For agent greeting ("Thank you for calling ___")
5. **ElevenLabs account** - You're buying today

---

## Ready to Build

Once ElevenLabs is set up, I can create:
1. All n8n workflow JSON files
2. Supabase schema and setup
3. ElevenLabs agent system prompt
4. KB indexing pipeline
5. Full documentation

Let me know when you're ready to proceed with Phase 1.
