-- ============================================================================
-- MBACIO Virtual Receptionist - Supabase Database Schema
-- Project: MBACIO VOIP LAYER
-- URL: https://fhhorzemcxtiifirbcia.supabase.co
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- CALLER IDENTITY TABLE
-- Purpose: Store known contacts for identity validation during calls
-- Source: Synced from SharePoint spreadsheet or manual entry
-- ============================================================================
CREATE TABLE IF NOT EXISTS caller_identity (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Contact information (used for validation)
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,

    -- Company association
    company_name TEXT,
    department TEXT,

    -- Classification flags
    is_vip BOOLEAN DEFAULT FALSE,
    tier TEXT CHECK (tier IN ('standard', 'premium', 'enterprise')) DEFAULT 'standard',

    -- Source tracking (where this record came from)
    source TEXT CHECK (source IN ('sharepoint', 'manual', 'api')) DEFAULT 'manual',
    sharepoint_id TEXT,

    -- Additional metadata
    notes TEXT,
    tags TEXT[],

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_contact_at TIMESTAMPTZ,

    -- Require at least email or phone
    CONSTRAINT email_phone_required CHECK (email IS NOT NULL OR phone IS NOT NULL)
);

-- Indexes for fast lookup during calls
CREATE INDEX IF NOT EXISTS idx_caller_identity_email ON caller_identity(LOWER(email));
CREATE INDEX IF NOT EXISTS idx_caller_identity_phone ON caller_identity(phone);
CREATE INDEX IF NOT EXISTS idx_caller_identity_name ON caller_identity(LOWER(name));
CREATE INDEX IF NOT EXISTS idx_caller_identity_company ON caller_identity(LOWER(company_name));

-- ============================================================================
-- CALL LOG TABLE
-- Purpose: Track all incoming calls, their status, and outcomes
-- ============================================================================
CREATE TABLE IF NOT EXISTS call_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- External identifiers
    elevenlabs_conversation_id TEXT UNIQUE NOT NULL,
    dialpad_call_id TEXT,

    -- Caller information (captured during call)
    caller_phone TEXT,
    caller_name TEXT,
    caller_email TEXT,
    callback_number TEXT,
    company_name TEXT,

    -- Identity validation results
    identity_status TEXT CHECK (identity_status IN ('validated', 'partial_match', 'not_found', 'escalated')),
    identity_confidence INTEGER CHECK (identity_confidence >= 0 AND identity_confidence <= 100),
    matched_contact_id UUID REFERENCES caller_identity(id),

    -- Call classification
    intent TEXT CHECK (intent IN ('support', 'sales', 'billing', 'general')),

    -- Call content
    summary TEXT,
    transcript JSONB,

    -- Priority & SLA
    priority TEXT CHECK (priority IN ('P1', 'P2', 'P3', 'P4')),
    priority_confidence INTEGER,
    priority_reasoning TEXT,
    sla_response_due TIMESTAMPTZ,
    sla_resolution_due TIMESTAMPTZ,

    -- Outcome tracking
    outcome TEXT CHECK (outcome IN ('resolved', 'escalated', 'callback_scheduled', 'dropped', 'voicemail')),
    resolution_method TEXT,  -- 'kb_article', 'agent_knowledge', 'escalated_to_human'
    kb_article_used UUID,
    escalation_reason TEXT,

    -- Call metrics
    duration_seconds INTEGER,
    status TEXT CHECK (status IN ('in_progress', 'completed', 'failed')) DEFAULT 'in_progress',

    -- Recording
    recording_url TEXT,

    -- Email notification tracking
    email_sent BOOLEAN DEFAULT FALSE,
    email_sent_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Indexes for querying and reporting
CREATE INDEX IF NOT EXISTS idx_call_log_conversation_id ON call_log(elevenlabs_conversation_id);
CREATE INDEX IF NOT EXISTS idx_call_log_status ON call_log(status);
CREATE INDEX IF NOT EXISTS idx_call_log_priority ON call_log(priority);
CREATE INDEX IF NOT EXISTS idx_call_log_created_at ON call_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_call_log_outcome ON call_log(outcome);

-- ============================================================================
-- KNOWLEDGE BASE EMBEDDINGS TABLE
-- Purpose: Store vectorized KB content for semantic search (First Call Resolution)
-- Source: Indexed from SharePoint documents
-- ============================================================================
CREATE TABLE IF NOT EXISTS kb_embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Content
    title TEXT NOT NULL,
    content TEXT NOT NULL,

    -- Vector embedding (OpenAI text-embedding-3-small = 1536 dimensions)
    embedding vector(1536),

    -- Source tracking
    source TEXT CHECK (source IN ('sharepoint', 'manual', 'auto_generated')) DEFAULT 'sharepoint',
    source_url TEXT,
    sharepoint_item_id TEXT,

    -- Classification for filtering
    category TEXT,  -- 'fishbowl', 'network', 'email', 'hardware', etc.
    product TEXT,   -- Specific product name
    tags TEXT[],

    -- Content metadata
    document_type TEXT,  -- 'troubleshooting', 'process', 'guide', 'faq'

    -- Version control
    version INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,

    -- Usage analytics
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,
    success_rate NUMERIC(5,2),  -- Percentage of times this resolved the issue

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vector similarity search index (IVFFlat for performance)
CREATE INDEX IF NOT EXISTS idx_kb_embeddings_vector
    ON kb_embeddings USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_kb_embeddings_category ON kb_embeddings(category);
CREATE INDEX IF NOT EXISTS idx_kb_embeddings_product ON kb_embeddings(product);
CREATE INDEX IF NOT EXISTS idx_kb_embeddings_active ON kb_embeddings(is_active);

-- ============================================================================
-- EMAIL NOTIFICATIONS TABLE
-- Purpose: Track all email notifications sent (audit trail)
-- ============================================================================
CREATE TABLE IF NOT EXISTS email_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Reference to call
    call_log_id UUID REFERENCES call_log(id),

    -- Email details
    recipient TEXT NOT NULL,
    subject TEXT NOT NULL,
    body_preview TEXT,  -- First 500 chars of email body

    -- Status tracking
    status TEXT CHECK (status IN ('sent', 'failed', 'queued')) NOT NULL,
    smtp_message_id TEXT,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    sent_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_email_notifications_call ON email_notifications(call_log_id);
CREATE INDEX IF NOT EXISTS idx_email_notifications_status ON email_notifications(status);

-- ============================================================================
-- WORKFLOW ERRORS TABLE
-- Purpose: Log n8n workflow errors for debugging and monitoring
-- ============================================================================
CREATE TABLE IF NOT EXISTS workflow_errors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Error context
    workflow_name TEXT NOT NULL,
    node_name TEXT,
    conversation_id TEXT,

    -- Error details
    error_message TEXT NOT NULL,
    error_stack TEXT,
    input_data JSONB,

    -- Resolution tracking
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT,

    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workflow_errors_created ON workflow_errors(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_workflow_errors_resolved ON workflow_errors(resolved);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function: Search KB with vector similarity
CREATE OR REPLACE FUNCTION search_kb(
    query_embedding vector(1536),
    match_threshold float DEFAULT 0.7,
    match_count int DEFAULT 5,
    filter_category text DEFAULT NULL,
    filter_product text DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    content TEXT,
    source_url TEXT,
    category TEXT,
    product TEXT,
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        kb.id,
        kb.title,
        kb.content,
        kb.source_url,
        kb.category,
        kb.product,
        1 - (kb.embedding <=> query_embedding) as similarity
    FROM kb_embeddings kb
    WHERE kb.is_active = TRUE
    AND (filter_category IS NULL OR kb.category = filter_category)
    AND (filter_product IS NULL OR kb.product = filter_product)
    AND 1 - (kb.embedding <=> query_embedding) > match_threshold
    ORDER BY kb.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- Function: Validate caller identity with fuzzy matching
CREATE OR REPLACE FUNCTION validate_caller(
    p_name TEXT,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL
)
RETURNS TABLE (
    contact_id UUID,
    contact_name TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    contact_company TEXT,
    match_score INTEGER,
    match_type TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH scored_matches AS (
        SELECT
            ci.id,
            ci.name,
            ci.email,
            ci.phone,
            ci.company_name,
            (
                -- Name matching (0-40 points)
                CASE
                    WHEN LOWER(ci.name) = LOWER(p_name) THEN 40
                    WHEN LOWER(ci.name) LIKE '%' || LOWER(p_name) || '%' THEN 25
                    WHEN LOWER(p_name) LIKE '%' || LOWER(ci.name) || '%' THEN 25
                    ELSE 0
                END
                +
                -- Email matching (0-35 points)
                CASE
                    WHEN p_email IS NOT NULL AND LOWER(ci.email) = LOWER(p_email) THEN 35
                    WHEN p_email IS NOT NULL AND LOWER(ci.email) LIKE '%' || SPLIT_PART(LOWER(p_email), '@', 1) || '%' THEN 15
                    ELSE 0
                END
                +
                -- Phone matching (0-25 points)
                CASE
                    WHEN p_phone IS NOT NULL AND ci.phone = p_phone THEN 25
                    WHEN p_phone IS NOT NULL AND RIGHT(ci.phone, 7) = RIGHT(p_phone, 7) THEN 15
                    ELSE 0
                END
            ) as score
        FROM caller_identity ci
        WHERE
            (LOWER(ci.name) LIKE '%' || LOWER(p_name) || '%' OR LOWER(p_name) LIKE '%' || LOWER(ci.name) || '%')
            OR (p_email IS NOT NULL AND LOWER(ci.email) = LOWER(p_email))
            OR (p_phone IS NOT NULL AND (ci.phone = p_phone OR RIGHT(ci.phone, 7) = RIGHT(p_phone, 7)))
    )
    SELECT
        sm.id as contact_id,
        sm.name as contact_name,
        sm.email as contact_email,
        sm.phone as contact_phone,
        sm.company_name as contact_company,
        sm.score as match_score,
        CASE
            WHEN sm.score >= 80 THEN 'validated'
            WHEN sm.score >= 50 THEN 'partial_match'
            ELSE 'not_found'
        END as match_type
    FROM scored_matches sm
    WHERE sm.score > 20
    ORDER BY sm.score DESC
    LIMIT 5;
END;
$$;

-- Function: Update KB article usage stats
CREATE OR REPLACE FUNCTION update_kb_usage(
    p_article_id UUID,
    p_was_successful BOOLEAN
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE kb_embeddings
    SET
        usage_count = usage_count + 1,
        last_used_at = NOW(),
        success_rate = CASE
            WHEN usage_count = 0 THEN
                CASE WHEN p_was_successful THEN 100.0 ELSE 0.0 END
            ELSE
                (success_rate * usage_count + CASE WHEN p_was_successful THEN 100.0 ELSE 0.0 END) / (usage_count + 1)
        END,
        updated_at = NOW()
    WHERE id = p_article_id;
END;
$$;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger function: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all relevant tables
DROP TRIGGER IF EXISTS call_log_updated_at ON call_log;
CREATE TRIGGER call_log_updated_at
    BEFORE UPDATE ON call_log
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS caller_identity_updated_at ON caller_identity;
CREATE TRIGGER caller_identity_updated_at
    BEFORE UPDATE ON caller_identity
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS kb_embeddings_updated_at ON kb_embeddings;
CREATE TRIGGER kb_embeddings_updated_at
    BEFORE UPDATE ON kb_embeddings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- SAMPLE DATA (for testing)
-- ============================================================================

-- Insert sample caller identities
INSERT INTO caller_identity (name, email, phone, company_name, is_vip, tier) VALUES
    ('John Smith', 'john.smith@acmecorp.com', '+15551234567', 'Acme Corporation', false, 'standard'),
    ('Jane Doe', 'jane.doe@techstartup.io', '+15559876543', 'Tech Startup Inc', true, 'premium'),
    ('Bob Johnson', 'bob@enterprise.com', '+15555551234', 'Enterprise Solutions', false, 'enterprise')
ON CONFLICT DO NOTHING;

-- Insert sample KB article
INSERT INTO kb_embeddings (title, content, category, product, document_type, source) VALUES
    ('Fishbowl Server Connection Error',
     'When users see "server cannot be reached" error in Fishbowl:

1. Click OK on the error dialog to dismiss it
2. On the login screen, click the DETAILS button to expand connection settings
3. Verify the Server Address matches your server hostname or IP
4. Check the Port number - the correct port should be 28192
5. If the port is incorrect (e.g., shows 1234), update it to 28192
6. Click Connect to retry

Common causes:
- Port was changed during update
- Network firewall blocking the port
- Server service not running

If issue persists after verifying settings, escalate to an engineer to check server status.',
     'software',
     'Fishbowl',
     'troubleshooting',
     'manual')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- VIEWS (for reporting and dashboards)
-- ============================================================================

-- View: Daily call summary
CREATE OR REPLACE VIEW daily_call_summary AS
SELECT
    DATE(created_at) as call_date,
    COUNT(*) as total_calls,
    COUNT(*) FILTER (WHERE outcome = 'resolved') as resolved_count,
    COUNT(*) FILTER (WHERE outcome = 'escalated') as escalated_count,
    COUNT(*) FILTER (WHERE priority = 'P1') as p1_count,
    COUNT(*) FILTER (WHERE priority = 'P2') as p2_count,
    COUNT(*) FILTER (WHERE priority = 'P3') as p3_count,
    COUNT(*) FILTER (WHERE priority = 'P4') as p4_count,
    AVG(duration_seconds) as avg_duration_seconds,
    ROUND(COUNT(*) FILTER (WHERE outcome = 'resolved') * 100.0 / NULLIF(COUNT(*), 0), 2) as resolution_rate
FROM call_log
WHERE status = 'completed'
GROUP BY DATE(created_at)
ORDER BY call_date DESC;

-- View: Identity validation stats
CREATE OR REPLACE VIEW identity_validation_stats AS
SELECT
    identity_status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM call_log
WHERE identity_status IS NOT NULL
GROUP BY identity_status;

-- ============================================================================
-- ROW LEVEL SECURITY (optional - enable if needed)
-- ============================================================================

-- Enable RLS on tables (uncomment if using service role key for all operations)
-- ALTER TABLE call_log ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE caller_identity ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE kb_embeddings ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- GRANTS (adjust based on your security requirements)
-- ============================================================================

-- Grant usage on all tables to authenticated users (if using RLS)
-- GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
-- GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

COMMENT ON TABLE call_log IS 'Tracks all incoming calls to the AI virtual receptionist';
COMMENT ON TABLE caller_identity IS 'Known contacts for identity validation during calls';
COMMENT ON TABLE kb_embeddings IS 'Knowledge base articles with vector embeddings for semantic search';
COMMENT ON TABLE email_notifications IS 'Audit trail of all email notifications sent';
COMMENT ON TABLE workflow_errors IS 'n8n workflow error logs for debugging';
