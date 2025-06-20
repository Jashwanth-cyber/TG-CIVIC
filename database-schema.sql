-- TG Civic Clean Database Schema
-- This will completely reset and recreate all tables with correct types

-- First, drop all existing tables and their dependencies
DROP TABLE IF EXISTS complaint_updates CASCADE;
DROP TABLE IF EXISTS complaint_attachments CASCADE;
DROP TABLE IF EXISTS complaints CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop any existing functions
DROP FUNCTION IF EXISTS generate_complaint_number() CASCADE;
DROP FUNCTION IF EXISTS set_complaint_number() CASCADE;

-- Create users table with INTEGER primary key
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

-- Create complaints table with INTEGER primary key and foreign keys
CREATE TABLE complaints (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(100) NOT NULL,
  priority VARCHAR(20) NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved', 'rejected')),
  location VARCHAR(255),
  landmark VARCHAR(255),
  citizen_id INTEGER NOT NULL,
  assigned_admin_id INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP WITH TIME ZONE,
  admin_notes TEXT,
  complaint_number VARCHAR(20) UNIQUE NOT NULL DEFAULT ''
);

-- Create complaint attachments table with INTEGER foreign key
CREATE TABLE complaint_attachments (
  id SERIAL PRIMARY KEY,
  complaint_id INTEGER NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_url TEXT NOT NULL,
  file_type VARCHAR(100),
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create complaint updates table with INTEGER foreign keys
CREATE TABLE complaint_updates (
  id SERIAL PRIMARY KEY,
  complaint_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  message TEXT NOT NULL,
  is_internal BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add foreign key constraints after table creation
ALTER TABLE complaints 
ADD CONSTRAINT fk_complaints_citizen_id 
FOREIGN KEY (citizen_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE complaints 
ADD CONSTRAINT fk_complaints_assigned_admin_id 
FOREIGN KEY (assigned_admin_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE complaint_attachments 
ADD CONSTRAINT fk_complaint_attachments_complaint_id 
FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE;

ALTER TABLE complaint_updates 
ADD CONSTRAINT fk_complaint_updates_complaint_id 
FOREIGN KEY (complaint_id) REFERENCES complaints(id) ON DELETE CASCADE;

ALTER TABLE complaint_updates 
ADD CONSTRAINT fk_complaint_updates_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_complaints_citizen_id ON complaints(citizen_id);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_created_at ON complaints(created_at);
CREATE INDEX idx_complaints_number ON complaints(complaint_number);
CREATE INDEX idx_complaint_updates_complaint_id ON complaint_updates(complaint_id);
CREATE INDEX idx_complaint_attachments_complaint_id ON complaint_attachments(complaint_id);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_updates ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public registration" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Citizens can create complaints" ON complaints;
DROP POLICY IF EXISTS "Users can view complaints" ON complaints;
DROP POLICY IF EXISTS "Admins can update complaints" ON complaints;
DROP POLICY IF EXISTS "Citizens can update own complaints" ON complaints;
DROP POLICY IF EXISTS "Users can create updates" ON complaint_updates;
DROP POLICY IF EXISTS "Users can view updates" ON complaint_updates;
DROP POLICY IF EXISTS "Users can create attachments" ON complaint_attachments;
DROP POLICY IF EXISTS "Users can view attachments" ON complaint_attachments;

-- Create permissive policies for now (can be tightened later)
CREATE POLICY "Allow all operations on users" ON users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations on complaints" ON complaints FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations on complaint_updates" ON complaint_updates FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all operations on complaint_attachments" ON complaint_attachments FOR ALL USING (true) WITH CHECK (true);

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
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Function to generate complaint number
CREATE OR REPLACE FUNCTION generate_complaint_number()
RETURNS TEXT AS $$
DECLARE
  complaint_number TEXT;
  next_id INTEGER;
BEGIN
  -- Get a unique number based on current max ID
  SELECT COALESCE(MAX(id), 0) + 1 INTO next_id FROM complaints;
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
  NEW.updated_at := CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_set_complaint_number ON complaints;
CREATE TRIGGER trigger_set_complaint_number
  BEFORE INSERT OR UPDATE ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION set_complaint_number();

-- Verify tables were created successfully
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name IN ('users', 'complaints', 'complaint_attachments', 'complaint_updates')
ORDER BY table_name, ordinal_position;

SELECT 'Database schema created successfully with INTEGER types!' as status;
