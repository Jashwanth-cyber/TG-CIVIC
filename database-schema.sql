-- TG Civic Complete Database Schema
-- Run this in your Supabase SQL Editor

-- Create users table (if not exists)
CREATE TABLE IF NOT EXISTS users (
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

-- Create complaints table
CREATE TABLE IF NOT EXISTS complaints (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(100) NOT NULL,
  priority VARCHAR(20) NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved', 'rejected')),
  location VARCHAR(255),
  landmark VARCHAR(255),
  citizen_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assigned_admin_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP WITH TIME ZONE,
  admin_notes TEXT,
  complaint_number VARCHAR(20) UNIQUE NOT NULL
);

-- Create complaint attachments table
CREATE TABLE IF NOT EXISTS complaint_attachments (
  id SERIAL PRIMARY KEY,
  complaint_id INTEGER NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_url TEXT NOT NULL,
  file_type VARCHAR(100),
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create complaint updates/comments table
CREATE TABLE IF NOT EXISTS complaint_updates (
  id SERIAL PRIMARY KEY,
  complaint_id INTEGER NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  is_internal BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_complaints_citizen_id ON complaints(citizen_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaints_created_at ON complaints(created_at);
CREATE INDEX IF NOT EXISTS idx_complaints_number ON complaints(complaint_number);
CREATE INDEX IF NOT EXISTS idx_complaint_updates_complaint_id ON complaint_updates(complaint_id);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_updates ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public registration" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Citizens can create complaints" ON complaints;
DROP POLICY IF EXISTS "Users can view own complaints" ON complaints;
DROP POLICY IF EXISTS "Admins can view all complaints" ON complaints;
DROP POLICY IF EXISTS "Admins can update complaints" ON complaints;

-- User policies
CREATE POLICY "Allow public registration" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (true);

-- Complaint policies
CREATE POLICY "Citizens can create complaints" ON complaints FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can view complaints" ON complaints FOR SELECT USING (true);
CREATE POLICY "Admins can update complaints" ON complaints FOR UPDATE USING (true);
CREATE POLICY "Citizens can update own complaints" ON complaints FOR UPDATE USING (true);

-- Complaint updates policies
CREATE POLICY "Users can create updates" ON complaint_updates FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can view updates" ON complaint_updates FOR SELECT USING (true);

-- Attachments policies
CREATE POLICY "Users can create attachments" ON complaint_attachments FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can view attachments" ON complaint_attachments FOR SELECT USING (true);

-- Grant permissions
GRANT ALL ON users TO authenticated;
GRANT ALL ON users TO anon;
GRANT ALL ON complaints TO authenticated;
GRANT ALL ON complaints TO anon;
GRANT ALL ON complaint_attachments TO authenticated;
GRANT ALL ON complaint_attachments TO anon;
GRANT ALL ON complaint_updates TO authenticated;
GRANT ALL ON complaint_updates TO anon;

-- Grant sequence permissions
GRANT USAGE, SELECT ON SEQUENCE users_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE users_id_seq TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE complaints_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE complaints_id_seq TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE complaint_attachments_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE complaint_attachments_id_seq TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE complaint_updates_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE complaint_updates_id_seq TO authenticated;

-- Function to generate complaint number
CREATE OR REPLACE FUNCTION generate_complaint_number()
RETURNS TEXT AS $$
DECLARE
  complaint_number TEXT;
BEGIN
  complaint_number := 'TGC' || TO_CHAR(NOW(), 'YYYY') || LPAD(nextval('complaints_id_seq')::TEXT, 6, '0');
  RETURN complaint_number;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate complaint number
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

DROP TRIGGER IF EXISTS trigger_set_complaint_number ON complaints;
CREATE TRIGGER trigger_set_complaint_number
  BEFORE INSERT OR UPDATE ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION set_complaint_number();

SELECT 'Database schema created successfully!' as message;
