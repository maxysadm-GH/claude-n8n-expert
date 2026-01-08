# Pre-Implementation Questions

Before I can begin autonomous implementation, I need answers to the following questions. These are organized by priority - **Critical** items will block progress, while **Nice-to-have** can be resolved later.

---

## CRITICAL - Must Answer Before Starting

### 1. Platform Choices

**Q1.1: Database for call logging - Airtable or Supabase?**
- The draft mentions both. Which do you prefer?
- Recommendation: Supabase for more flexibility and SQL capabilities

**Q1.2: Knowledge Base storage - Google Drive or SharePoint?**
- README mentions Teams/SharePoint integration
- Draft mentions migrating to Google Drive
- Which is the primary source?

**Q1.3: n8n hosting - Cloud or Self-hosted?**
- This affects webhook URLs and deployment approach
- Do you have an existing n8n Cloud account?

---

### 2. External Service Access

**Q2.1: Dialpad Plan Level**
- Do you have Dialpad Pro or Enterprise? (Required for API access)
- Do you have admin access to configure IVR menus?
- Can you access the Dialpad API documentation/credentials?

**Q2.2: ElevenLabs Plan & Features**
- Do you have access to ElevenLabs Conversational AI? (Starter plan or higher)
- Have you used ElevenLabs agents before?
- Is SIP integration available on your plan?

**Q2.3: Existing Credentials Available**
- [ ] OpenAI API key
- [ ] ElevenLabs API key
- [ ] Dialpad API credentials
- [ ] Qdrant API key (or will self-host?)
- [ ] Airtable/Supabase credentials

---

### 3. Business Requirements

**Q3.1: SLA Rules**
- What defines "urgent" vs "normal" priority?
- Example: "If customer mentions 'down' or 'not working' = urgent"
- Are there specific response time targets?

**Q3.2: Escalation Targets**
- Who are the support agents to check presence for?
- Do you have their Dialpad user IDs or emails?
- Fallback if everyone is unavailable?

**Q3.3: Email Configuration**
- Confirm: outcomes go to support@mbacio.com?
- What email service will send these? (n8n native, SMTP, SendGrid?)
- Any specific template requirements?

---

## IMPORTANT - Needed for Full Implementation

### 4. Knowledge Base Content

**Q4.1: Existing KB Structure**
- Do you have existing documentation files?
- Formats: PDF, Word, Markdown, web pages?
- Approximate size (number of documents, pages)?

**Q4.2: KB Separation**
- Should support/sales/payments have separate KBs?
- Or one KB with tagged sections?

---

### 5. Voice & Conversation Design

**Q5.1: Brand Voice**
- Company name for greetings?
- Formal or casual tone?
- Any specific phrases to use/avoid?

**Q5.2: ElevenLabs Voice**
- Preference for voice gender/style?
- Or do you have a cloned voice already?

---

### 6. Scheduling Integration

**Q6.1: Calendar System**
- Outlook/Microsoft 365 for callback scheduling?
- Or Google Calendar?
- Who should receive scheduled callbacks?

---

## NICE-TO-HAVE - Can Iterate Later

### 7. Advanced Features

**Q7.1: Documentation Auto-Generation**
- What format should generated docs be in?
- Where should they be stored?
- Approval workflow before KB addition?

**Q7.2: Analytics & Reporting**
- What metrics matter most?
- Daily/weekly reports needed?
- Dashboard preferences?

---

## Quick Reference - What I Need to Start

At minimum, to begin building workflow templates:

1. **Database choice**: Airtable or Supabase
2. **KB storage choice**: Google Drive or SharePoint
3. **Company name** for greetings
4. **Email recipient** for outcomes

Everything else can be configured via environment variables later.

---

## Response Format

Please answer in this format:

```
Q1.1: [Your answer]
Q1.2: [Your answer]
Q1.3: [Your answer]
...
```

Or just provide the information in natural language and I'll extract what I need.
