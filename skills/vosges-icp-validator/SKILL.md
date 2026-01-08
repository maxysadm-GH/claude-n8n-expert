# Vosges Haut-Chocolat ICP Validator Skill

## Activation Triggers
- Validating Vosges marketing campaigns
- Creating luxury chocolate marketing content
- ICP scoring for DTC, B2B, Wholesale channels
- Brand alignment checking

## Quick Reference

### Brand Essence
- **Founded:** 1998, Chicago by Katrina Markoff (Le Cordon Bleu)
- **Tagline:** "Travel the World Through Chocolate®"
- **Signature:** Purple boxes, exotic global flavors
- **Certifications:** WBE, DBE, Fair Trade, Rainforest Alliance

### Brand Voice
✅ **DO:** Sensory language, cultural stories, discovery, craftsmanship, "journey" metaphors
❌ **DON'T:** Mass-market, discount language, pretentious, ignore stories

### ICP Segments

**DTC Gift Buyers:**
- Age 30-55, $100K+ income, urban professionals
- Value quality, unique experiences, gifting as relationship-building

**B2B Corporate:**
- Mid-market to enterprise, Finance/Tech/Professional Services
- Client appreciation, employee recognition, holiday programs
- Decision makers: EAs, HR Directors, Marketing Directors

**Self-Purchasers:**
- Foodies, subscription-oriented, single-origin enthusiasts

### Scoring Rubric (100 points)

| Category | Points | Key Criteria |
|----------|--------|--------------|
| Brand Alignment | 30 | Voice, visuals, story integration |
| ICP Targeting | 25 | Audience, occasion, value prop |
| Competitive Differentiation | 20 | Unique vs Godiva/Lindt, exotic factor |
| Conversion Potential | 15 | CTA, urgency, trust signals |
| Technical Execution | 10 | Format, quality |

### Score Interpretation
- 🟢 **90-100:** Ready to launch
- 🟡 **75-89:** Minor refinements
- 🟠 **60-74:** Significant work needed
- 🔴 **<60:** Major revision or reject

### Competitors
**Direct:** Compartes, La Maison du Chocolat, Recchiuti
**Mass Luxury:** Godiva, Lindt, Ghirardelli

### Vosges Advantages
1. First-mover in exotic flavors (bacon bars, curry truffles)
2. Deep storytelling with each collection
3. WBE/DBE certifications for corporate diversity
4. Sustainable luxury positioning

### Visual Identity
- **Primary:** Deep purple
- **Secondary:** Gold accents, earth tones
- **Photography:** Moody, dramatic, texture-focused, ingredient origins

### Hero Products
- Exotic Truffle Collection (16-piece flagship)
- Mo's Milk Chocolate Bacon Bar
- Black Pearl Chocolat
- Grande Gift Tower (corporate hero)

### Seasonal Focus
- **Q4:** All-out holiday + corporate gifting
- **Valentine's/Mother's Day:** Targeted occasions
- **Summer:** Subscriptions, efficiency mode

### Integration Channels
- **Shopify:** vosgeschocolate.myshopify.com
- **ShipStation:** Store ID 273669 (Shopify), 219870 (BD)
- **HubSpot:** CRM for B2B
- **Social:** Facebook, Instagram, LinkedIn

## Validator System Prompt Template

```
You are the official ICP Validator for Vosges Haut-Chocolat, a luxury artisanal chocolatier known for exotic global flavor combinations.

BRAND CONTEXT:
- Founded 1998 in Chicago by Katrina Markoff (Le Cordon Bleu)
- Tagline: "Travel the World Through Chocolate®"
- Known for: Exotic ingredients (bacon bars, curry truffles, wasabi)
- Signature: Purple boxes, experiential storytelling

SCORING FORMAT:
1. **Score:** X/100 with emoji (🟢 90+, 🟡 75-89, 🟠 60-74, 🔴 <60)
2. **Summary:** 1-2 sentence verdict
3. **Strengths:** What's working (bullets)
4. **Improvements:** Specific, actionable changes (bullets)
5. **Revised Version:** If copy, provide improved alternative

Be constructive, specific, and expert-level. Channel the voice of a CMO who deeply understands luxury chocolate marketing.
```

## n8n Workflow Patterns

### Chat Trigger Version
- Use `@n8n/n8n-nodes-langchain.chatTrigger`
- Connect to Claude 3.5 Sonnet via OpenRouter
- System message contains full ICP knowledge

### Teams Bot Version
- Webhook receives Teams Outgoing Webhook
- Parse message, extract text/attachments
- Process through Claude
- Return Adaptive Card response

### Airtable Logging
Log all validations to track:
- Content type (headline, image, video, campaign)
- Score
- Timestamp
- User who requested

## Test Payloads

**Should PASS (90+):**
```
"Journey Through Morocco: New Saffron & Rose Truffle Collection"
```

**Should FAIL (<60):**
```
"50% OFF CHOCOLATE FLASH SALE TODAY!"
```
