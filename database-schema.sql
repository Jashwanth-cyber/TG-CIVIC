-- TG Civic Simplified Database Schema (No Foreign Keys)
-- This creates working tables without foreign key constraints to avoid type conflicts

-- Clean slate: drop everything
DROP TABLE IF EXISTS complaint_updates CASCADE;
DROP TABLE IF EXISTS complaint_attachments CASCADE;
DROP TABLE IF EXISTS complaints CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP FUNCTION IF EXISTS generate_complaint_number() CASCADE;
DROP FUNCTION IF EXISTS set_complaint_number() CASCADE;

-- Create users table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL CHECK (role IN ('citizen', 'admin')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  last_login TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT true,
  email_verified BOOLEAN DEFAULT false
);

-- Create complaints table (NO FOREIGN KEY CONSTRAINTS)
CREATE TABLE complaints (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(100) NOT NULL,
  priority VARCHAR(20) NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved', 'rejected')),
  location VARCHAR(255),
  landmark VARCHAR(255),
  citizen_id INTEGER NOT NULL,  -- References users.id but no constraint
  assigned_admin_id INTEGER,    -- References users.id but no constraint
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP WITH TIME ZONE,
  admin_notes TEXT,
  complaint_number VARCHAR(20) UNIQUE NOT NULL DEFAULT ''
);

-- Create complaint attachments table (NO FOREIGN KEY CONSTRAINTS)
CREATE TABLE complaint_attachments (
  id SERIAL PRIMARY KEY,
  complaint_id INTEGER NOT NULL,  -- References complaints.id but no constraint
  file_name VARCHAR(255) NOT NULL,
  file_url TEXT NOT NULL,
  file_type VARCHAR(100),
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create complaint updates table (NO FOREIGN KEY CONSTRAINTS)
CREATE TABLE complaint_updates (
  id SERIAL PRIMARY KEY,
  complaint_id INTEGER NOT NULL,  -- References complaints.id but no constraint
  user_id INTEGER NOT NULL,       -- References users.id but no constraint
  message TEXT NOT NULL,
  is_internal BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_complaints_citizen_id ON complaints(citizen_id);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_created_at ON complaints(created_at);
CREATE INDEX idx_complaints_number ON complaints(complaint_number);
CREATE INDEX idx_complaint_updates_complaint_id ON complaint_updates(complaint_id);
CREATE INDEX idx_complaint_attachments_complaint_id ON complaint_attachments(complaint_id);

-- Enable Row Level Security with permissive policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_updates ENABLE ROW LEVEL SECURITY;

-- Very permissive policies (you can tighten these later)
CREATE POLICY "allow_all_users" ON users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_complaints" ON complaints FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_attachments" ON complaint_attachments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_updates" ON complaint_updates FOR ALL USING (true) WITH CHECK (true);

-- Grant permissions
GRANT ALL ON users TO anon, authenticated;
GRANT ALL ON complaints TO anon, authenticated;
GRANT ALL ON complaint_attachments TO anon, authenticated;
GRANT ALL ON complaint_updates TO anon, authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Function to generate complaint numbers
CREATE OR REPLACE FUNCTION generate_complaint_number()
RETURNS TEXT AS $$
DECLARE
  complaint_number TEXT;
  next_id INTEGER;
BEGIN
  SELECT COALESCE(MAX(id), 0) + 1 INTO next_id FROM complaints;
  complaint_number := 'TGC' || TO_CHAR(NOW(), 'YYYY') || LPAD(next_id::TEXT, 6, '0');
  RETURN complaint_number;
END;
$$ LANGUAGE plpgsql;

-- Trigger function to auto-set complaint number
CREATE OR REPLACE FUNCTION set_complaint_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.complaint_number IS NULL OR NEW.complaint_number = '' THEN
    NEW.complaint_number := generate_complaint_number();
  END IF;
  NEW.updated_at := CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER trigger_set_complaint_number
  BEFORE INSERT OR UPDATE ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION set_complaint_number();

-- Success message
SELECT 'SUCCESS: Database created without foreign key constraints!' as result;
SELECT 'Tables: users, complaints, complaint_attachments, complaint_updates' as tables_created;
SELECT 'All tables use SERIAL (INTEGER) primary keys' as note;
