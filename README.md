# MBaCio Virtual Receptionist

AI-powered virtual receptionist using ElevenLabs Conversational AI, n8n workflows, and Supabase.

## Overview

A 5-layer approach to never missing a call:

| Layer | Goal | Implementation |
|-------|------|----------------|
| **1** | Never lose a call | Every call logged to Supabase |
| **2** | Understand intent + validate identity | AI conversation, no IVR menu |
| **3** | Log requests | Email to support@mbacio.com |
| **4** | Assess priority | Automatic P1-P4 classification |
| **5** | First call resolution | KB-powered troubleshooting |

## Tech Stack

- **ElevenLabs Conversational AI** - Voice agent handling calls
- **n8n** - Workflow orchestration
- **Supabase** - Database + vector search (pgvector)
- **Dialpad** - Phone system with SIP trunking
- **SharePoint** - Knowledge base source

## Quick Start

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for complete setup instructions.

```bash
# 1. Set up Supabase schema
# Copy database/schema.sql to Supabase SQL Editor and run

# 2. Import n8n workflow
# Import workflows/01-call-handler.json to n8n

# 3. Configure ElevenLabs agent
# Use elevenlabs/agent_config.md for system prompt and tools

# 4. Connect Dialpad to ElevenLabs via SIP trunk
```

## Project Structure

```
├── database/
│   └── schema.sql              # Supabase tables and functions
├── workflows/
│   └── 01-call-handler.json    # Main n8n workflow
├── templates/
│   ├── identity_validation_template.csv
│   └── email_notification.html
├── elevenlabs/
│   └── agent_config.md         # Agent system prompt and tools
├── docs/
│   ├── PROJECT_PLAN.md         # Initial project analysis
│   └── ARCHITECTURE_V2.md      # Simplified architecture
├── SETUP_GUIDE.md              # Step-by-step setup
└── README.md
```

## Architecture

```
Incoming Call
     │
     ▼
Dialpad (SIP) ──────────────▶ ElevenLabs AI Agent
                                    │
                                    │ webhooks
                                    ▼
                              n8n Workflows
                                    │
              ┌─────────────────────┼─────────────────────┐
              ▼                     ▼                     ▼
       Identity              KB Search              Email
       Validation           (pgvector)            Notification
              │                     │                     │
              └─────────────────────┼─────────────────────┘
                                    ▼
                               Supabase
```

## Configuration

### Environment Variables (n8n)

```
SUPABASE_URL=https://fhhorzemcxtiifirbcia.supabase.co
SUPABASE_ANON_KEY=your_key
OPENAI_API_KEY=your_key
```

### Supabase Project

- **Project**: MBACIO VOIP LAYER
- **URL**: https://fhhorzemcxtiifirbcia.supabase.co

## Documentation

- [Setup Guide](SETUP_GUIDE.md) - Complete installation instructions
- [Architecture](docs/ARCHITECTURE_V2.md) - Technical architecture details
- [ElevenLabs Config](elevenlabs/agent_config.md) - Agent configuration

## Status

- [x] Database schema design
- [x] n8n workflow structure
- [x] ElevenLabs agent configuration
- [x] Email notification templates
- [ ] SharePoint KB sync workflow
- [ ] ConnectWise integration
- [ ] Production deployment
