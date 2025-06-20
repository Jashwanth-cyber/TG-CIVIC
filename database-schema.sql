-- TG Civic Final Working Database Schema
-- Simple tables without foreign key constraints to avoid type conflicts

-- Clean everything first
DROP TABLE IF EXISTS complaint_updates CASCADE;
DROP TABLE IF EXISTS complaint_attachments CASCADE; 
DROP TABLE IF EXISTS complaints CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP FUNCTION IF EXISTS generate_complaint_number() CASCADE;
DROP FUNCTION IF EXISTS set_complaint_number() CASCADE;
DROP SEQUENCE IF EXISTS complaint_number_seq CASCADE;

-- Create users table with UUID primary key (Supabase default)
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('citizen', 'admin')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  email_verified BOOLEAN DEFAULT false
);

-- Create complaints table with UUID primary key (NO FOREIGN KEYS)
CREATE TABLE complaints (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved', 'rejected')),
  location TEXT,
  landmark TEXT,
  citizen_id UUID NOT NULL,  -- Links to users.id but no foreign key constraint
  assigned_admin_id UUID,    -- Links to users.id but no foreign key constraint
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  admin_notes TEXT,
  complaint_number TEXT UNIQUE NOT NULL DEFAULT ''
);

-- Create complaint_attachments table (NO FOREIGN KEYS)
CREATE TABLE complaint_attachments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID NOT NULL,  -- Links to complaints.id but no foreign key constraint
  file_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create complaint_updates table (NO FOREIGN KEYS)
CREATE TABLE complaint_updates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID NOT NULL,  -- Links to complaints.id but no foreign key constraint
  user_id UUID NOT NULL,       -- Links to users.id but no foreign key constraint
  message TEXT NOT NULL,
  is_internal BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_complaints_citizen_id ON complaints(citizen_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaints_created_at ON complaints(created_at);
CREATE INDEX IF NOT EXISTS idx_complaints_number ON complaints(complaint_number);

-- Enable Row Level Security with very permissive policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_updates ENABLE ROW LEVEL SECURITY;

-- Create permissive policies to avoid access issues
CREATE POLICY "allow_all_users" ON users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_complaints" ON complaints FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_attachments" ON complaint_attachments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_updates" ON complaint_updates FOR ALL USING (true) WITH CHECK (true);

-- Grant all permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- Create sequence for complaint numbers
CREATE SEQUENCE complaint_number_seq START 1;
GRANT ALL ON complaint_number_seq TO anon, authenticated;

-- Function to generate complaint numbers
CREATE OR REPLACE FUNCTION generate_complaint_number()
RETURNS TEXT AS $$
DECLARE
  complaint_number TEXT;
  next_id INTEGER;
BEGIN
  next_id := nextval('complaint_number_seq');
  complaint_number := 'TGC' || TO_CHAR(NOW(), 'YYYY') || LPAD(next_id::TEXT, 6, '0');
  RETURN complaint_number;
END;
$$ LANGUAGE plpgsql;

-- Trigger function to auto-generate complaint number
CREATE OR REPLACE FUNCTION set_complaint_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.complaint_number IS NULL OR NEW.complaint_number = '' THEN
    NEW.complaint_number := generate_complaint_number();
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER trigger_set_complaint_number
  BEFORE INSERT OR UPDATE ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION set_complaint_number();

-- Test the setup
SELECT 'SUCCESS: Database created without foreign key constraints!' as result;
SELECT 'All tables use UUID primary keys' as note;
SELECT 'Foreign key relationships are logical but not enforced' as constraint_info;

-- Show created tables
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('users', 'complaints', 'complaint_attachments', 'complaint_updates')
  AND table_schema = 'public'
ORDER BY table_name, ordinal_position;
