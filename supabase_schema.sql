-- Chemical Process Tracker Database Schema for Supabase PostgreSQL
-- This schema supports the Flutter app with offline-first approach

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create users table (for future authentication)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE,
    full_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create configurable_defaults table
CREATE TABLE IF NOT EXISTS configurable_defaults (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Labor rates
    labor_rate DECIMAL(10,2) DEFAULT 0.00,
    
    -- Rent rates
    rent_rate DECIMAL(10,2) DEFAULT 0.00,
    
    -- Account rates
    account_rate DECIMAL(10,2) DEFAULT 0.00,
    
    -- Byproduct rates
    cu_byproduct_rate DECIMAL(10,2) DEFAULT 0.00,
    tin_byproduct_rate DECIMAL(10,2) DEFAULT 0.00,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create production_batches table
CREATE TABLE IF NOT EXISTS production_batches (
    id TEXT PRIMARY KEY, -- Format: batch_YYYY-MM-DD
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Batch identification
    batch_date DATE NOT NULL,
    
    -- Primary product data
    patti_quantity DECIMAL(10,2) DEFAULT 0.00,
    patti_rate DECIMAL(10,2) DEFAULT 0.00,
    
    -- Material data (stored as JSONB for flexibility)
    base_materials JSONB DEFAULT '[]'::jsonb,
    derived_materials JSONB DEFAULT '[]'::jsonb,
    byproduct_materials JSONB DEFAULT '[]'::jsonb,
    manual_entries JSONB DEFAULT '[]'::jsonb,
    
    -- Calculation results (stored as JSONB)
    calculation_result JSONB DEFAULT '{}'::jsonb,
    
    -- Metadata
    is_completed BOOLEAN DEFAULT false,
    notes TEXT DEFAULT '',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_production_batches_batch_date ON production_batches(batch_date);
CREATE INDEX IF NOT EXISTS idx_production_batches_user_id ON production_batches(user_id);
CREATE INDEX IF NOT EXISTS idx_production_batches_created_at ON production_batches(created_at);
CREATE INDEX IF NOT EXISTS idx_production_batches_is_completed ON production_batches(is_completed);

-- Create indexes for configurable_defaults
CREATE INDEX IF NOT EXISTS idx_configurable_defaults_user_id ON configurable_defaults(user_id);
CREATE INDEX IF NOT EXISTS idx_configurable_defaults_updated_at ON configurable_defaults(updated_at);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_configurable_defaults_updated_at
    BEFORE UPDATE ON configurable_defaults
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_production_batches_updated_at
    BEFORE UPDATE ON production_batches
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE configurable_defaults ENABLE ROW LEVEL SECURITY;
ALTER TABLE production_batches ENABLE ROW LEVEL SECURITY;

-- For now, allow public access (can be restricted later with authentication)
CREATE POLICY "Allow public access to users" ON users
    FOR ALL USING (true);

CREATE POLICY "Allow public access to configurable_defaults" ON configurable_defaults
    FOR ALL USING (true);

CREATE POLICY "Allow public access to production_batches" ON production_batches
    FOR ALL USING (true);

-- Create view for batch analytics
CREATE OR REPLACE VIEW batch_analytics AS
SELECT 
    batch_date,
    patti_quantity,
    patti_rate,
    (patti_quantity * patti_rate) as total_revenue,
    (calculation_result->>'finalProfitLoss')::DECIMAL as profit_loss,
    (calculation_result->>'totalCost')::DECIMAL as total_cost,
    (calculation_result->>'efficiencyPercentage')::DECIMAL as efficiency,
    is_completed,
    created_at,
    updated_at
FROM production_batches
WHERE calculation_result IS NOT NULL;

-- Create view for monthly summary
CREATE OR REPLACE VIEW monthly_summary AS
SELECT 
    DATE_TRUNC('month', batch_date) as month,
    COUNT(*) as total_batches,
    SUM(patti_quantity) as total_quantity,
    SUM(patti_quantity * patti_rate) as total_revenue,
    SUM((calculation_result->>'finalProfitLoss')::DECIMAL) as total_profit_loss,
    SUM((calculation_result->>'totalCost')::DECIMAL) as total_cost,
    AVG((calculation_result->>'efficiencyPercentage')::DECIMAL) as avg_efficiency,
    COUNT(CASE WHEN is_completed = true THEN 1 END) as completed_batches
FROM production_batches
WHERE calculation_result IS NOT NULL
GROUP BY DATE_TRUNC('month', batch_date)
ORDER BY month DESC;

-- Create function for batch search
CREATE OR REPLACE FUNCTION search_batches(
    start_date DATE DEFAULT NULL,
    end_date DATE DEFAULT NULL,
    min_profit DECIMAL DEFAULT NULL,
    max_profit DECIMAL DEFAULT NULL,
    completed_only BOOLEAN DEFAULT false
)
RETURNS TABLE (
    id TEXT,
    batch_date DATE,
    patti_quantity DECIMAL,
    patti_rate DECIMAL,
    profit_loss DECIMAL,
    efficiency DECIMAL,
    is_completed BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pb.id,
        pb.batch_date,
        pb.patti_quantity,
        pb.patti_rate,
        (pb.calculation_result->>'finalProfitLoss')::DECIMAL,
        (pb.calculation_result->>'efficiencyPercentage')::DECIMAL,
        pb.is_completed,
        pb.created_at
    FROM production_batches pb
    WHERE 
        (start_date IS NULL OR pb.batch_date >= start_date) AND
        (end_date IS NULL OR pb.batch_date <= end_date) AND
        (min_profit IS NULL OR (pb.calculation_result->>'finalProfitLoss')::DECIMAL >= min_profit) AND
        (max_profit IS NULL OR (pb.calculation_result->>'finalProfitLoss')::DECIMAL <= max_profit) AND
        (completed_only = false OR pb.is_completed = true)
    ORDER BY pb.batch_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Create function for top performing batches
CREATE OR REPLACE FUNCTION get_top_batches(
    limit_count INTEGER DEFAULT 10,
    order_by TEXT DEFAULT 'profit' -- 'profit', 'efficiency', 'revenue'
)
RETURNS TABLE (
    id TEXT,
    batch_date DATE,
    patti_quantity DECIMAL,
    profit_loss DECIMAL,
    efficiency DECIMAL,
    revenue DECIMAL
) AS $$
BEGIN
    IF order_by = 'profit' THEN
        RETURN QUERY
        SELECT 
            pb.id,
            pb.batch_date,
            pb.patti_quantity,
            (pb.calculation_result->>'finalProfitLoss')::DECIMAL,
            (pb.calculation_result->>'efficiencyPercentage')::DECIMAL,
            (pb.patti_quantity * pb.patti_rate)::DECIMAL
        FROM production_batches pb
        WHERE pb.calculation_result IS NOT NULL
        ORDER BY (pb.calculation_result->>'finalProfitLoss')::DECIMAL DESC
        LIMIT limit_count;
    ELSIF order_by = 'efficiency' THEN
        RETURN QUERY
        SELECT 
            pb.id,
            pb.batch_date,
            pb.patti_quantity,
            (pb.calculation_result->>'finalProfitLoss')::DECIMAL,
            (pb.calculation_result->>'efficiencyPercentage')::DECIMAL,
            (pb.patti_quantity * pb.patti_rate)::DECIMAL
        FROM production_batches pb
        WHERE pb.calculation_result IS NOT NULL
        ORDER BY (pb.calculation_result->>'efficiencyPercentage')::DECIMAL DESC
        LIMIT limit_count;
    ELSE -- revenue
        RETURN QUERY
        SELECT 
            pb.id,
            pb.batch_date,
            pb.patti_quantity,
            (pb.calculation_result->>'finalProfitLoss')::DECIMAL,
            (pb.calculation_result->>'efficiencyPercentage')::DECIMAL,
            (pb.patti_quantity * pb.patti_rate)::DECIMAL
        FROM production_batches pb
        WHERE pb.calculation_result IS NOT NULL
        ORDER BY (pb.patti_quantity * pb.patti_rate) DESC
        LIMIT limit_count;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create function for efficiency analysis
CREATE OR REPLACE FUNCTION efficiency_analysis(
    days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
    date_range TEXT,
    avg_efficiency DECIMAL,
    max_efficiency DECIMAL,
    min_efficiency DECIMAL,
    total_batches INTEGER,
    profitable_batches INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CONCAT('Last ', days_back, ' days') as date_range,
        AVG((calculation_result->>'efficiencyPercentage')::DECIMAL) as avg_efficiency,
        MAX((calculation_result->>'efficiencyPercentage')::DECIMAL) as max_efficiency,
        MIN((calculation_result->>'efficiencyPercentage')::DECIMAL) as min_efficiency,
        COUNT(*)::INTEGER as total_batches,
        COUNT(CASE WHEN (calculation_result->>'finalProfitLoss')::DECIMAL > 0 THEN 1 END)::INTEGER as profitable_batches
    FROM production_batches
    WHERE 
        batch_date >= CURRENT_DATE - INTERVAL '1 day' * days_back
        AND calculation_result IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- Insert sample data for testing (optional)
-- INSERT INTO configurable_defaults (
--     labor_rate, rent_rate, account_rate, cu_byproduct_rate, tin_byproduct_rate
-- ) VALUES (
--     500.00, 200.00, 100.00, 50.00, 45.00
-- );

-- Grant permissions for the service role
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- Grant permissions for authenticated users (when authentication is implemented)
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Grant permissions for anonymous users (current setup)
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_production_batches_profit_loss ON production_batches 
USING btree (((calculation_result->>'finalProfitLoss')::DECIMAL));

CREATE INDEX IF NOT EXISTS idx_production_batches_efficiency ON production_batches 
USING btree (((calculation_result->>'efficiencyPercentage')::DECIMAL));

-- Comment on tables and important columns
COMMENT ON TABLE production_batches IS 'Main table storing all production batch data with JSONB fields for flexibility';
COMMENT ON COLUMN production_batches.id IS 'Unique identifier in format batch_YYYY-MM-DD';
COMMENT ON COLUMN production_batches.batch_date IS 'Date of the production batch';
COMMENT ON COLUMN production_batches.base_materials IS 'JSON array of base materials used in production';
COMMENT ON COLUMN production_batches.derived_materials IS 'JSON array of derived materials produced';
COMMENT ON COLUMN production_batches.byproduct_materials IS 'JSON array of byproduct materials';
COMMENT ON COLUMN production_batches.calculation_result IS 'JSON object containing P&L calculations and metrics';

COMMENT ON TABLE configurable_defaults IS 'Default rates and settings for the application';
COMMENT ON VIEW batch_analytics IS 'View providing analytics data for production batches';
COMMENT ON VIEW monthly_summary IS 'Monthly aggregated statistics for production batches';

-- Final message
SELECT 'Chemical Process Tracker database schema created successfully!' as message;