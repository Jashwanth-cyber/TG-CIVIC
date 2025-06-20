-- TG Civic Minimal Working Schema
-- This creates the absolute minimum needed tables

-- Drop everything completely
DROP TABLE IF EXISTS complaint_updates CASCADE;
DROP TABLE IF EXISTS complaint_attachments CASCADE;
DROP TABLE IF EXISTS complaints CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Disable RLS temporarily
SET session_replication_role = replica;

-- Create users table (minimal)
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  email_verified BOOLEAN DEFAULT false
);

-- Create complaints table (minimal, no constraints)
CREATE TABLE complaints (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  priority TEXT DEFAULT 'medium',
  status TEXT DEFAULT 'pending',
  location TEXT,
  landmark TEXT,
  citizen_id UUID,
  assigned_admin_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  admin_notes TEXT,
  complaint_number TEXT UNIQUE DEFAULT ''
);

-- Basic tables for future use (no constraints)
CREATE TABLE complaint_attachments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID,
  file_name TEXT,
  file_url TEXT,
  file_type TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE complaint_updates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID,
  user_id UUID,
  message TEXT,
  is_internal BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Re-enable normal mode
SET session_replication_role = DEFAULT;

-- Disable RLS for now to avoid permission issues
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE complaints DISABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_attachments DISABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_updates DISABLE ROW LEVEL SECURITY;

-- Grant all permissions
GRANT ALL ON users TO anon, authenticated, public;
GRANT ALL ON complaints TO anon, authenticated, public;
GRANT ALL ON complaint_attachments TO anon, authenticated, public;
GRANT ALL ON complaint_updates TO anon, authenticated, public;

-- Create sequence for complaint numbers
CREATE SEQUENCE IF NOT EXISTS complaint_number_seq START 1;
GRANT ALL ON complaint_number_seq TO anon, authenticated, public;

-- Simple function for complaint numbers
CREATE OR REPLACE FUNCTION generate_complaint_number()
RETURNS TEXT AS $$
BEGIN
  RETURN 'TGC' || TO_CHAR(NOW(), 'YYYY') || LPAD(nextval('complaint_number_seq')::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Simple trigger
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

CREATE TRIGGER trigger_set_complaint_number
  BEFORE INSERT OR UPDATE ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION set_complaint_number();

SELECT 'SUCCESS: Minimal database created!' as result;
