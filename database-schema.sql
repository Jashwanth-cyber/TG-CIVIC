-- TG Civic Database Schema (UUID Compatible)
-- This handles both UUID and INTEGER primary key scenarios

-- Step 1: Check what currently exists and clean up completely
DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Drop all views that might depend on our tables
    FOR r IN (SELECT table_name FROM information_schema.views WHERE table_schema = 'public' AND table_name LIKE '%complaint%' OR table_name LIKE '%user%') 
    LOOP
        EXECUTE 'DROP VIEW IF EXISTS ' || r.table_name || ' CASCADE';
    END LOOP;
    
    -- Drop all tables with CASCADE to remove all dependencies
    FOR r IN (SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('complaint_updates', 'complaint_attachments', 'complaints', 'users')) 
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || r.table_name || ' CASCADE';
    END LOOP;
END $$;

-- Step 2: Drop functions and triggers
DROP FUNCTION IF EXISTS generate_complaint_number() CASCADE;
DROP FUNCTION IF EXISTS set_complaint_number() CASCADE;

-- Step 3: Create users table with UUID primary key (Supabase standard)
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
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

-- Step 4: Create complaints table with UUID primary key and foreign keys
CREATE TABLE complaints (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(100) NOT NULL,
  priority VARCHAR(20) NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved', 'rejected')),
  location VARCHAR(255),
  landmark VARCHAR(255),
  citizen_id UUID NOT NULL,
  assigned_admin_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP WITH TIME ZONE,
  admin_notes TEXT,
  complaint_number VARCHAR(20) UNIQUE NOT NULL DEFAULT ''
);

-- Step 5: Create complaint_attachments table with UUID foreign key
CREATE TABLE complaint_attachments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_url TEXT NOT NULL,
  file_type VARCHAR(100),
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Step 6: Create complaint_updates table with UUID foreign keys
CREATE TABLE complaint_updates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  complaint_id UUID NOT NULL,
  user_id UUID NOT NULL,
  message TEXT NOT NULL,
  is_internal BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Step 7: Add foreign key constraints (now all UUIDs match)
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

-- Step 8: Create indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_complaints_citizen_id ON complaints(citizen_id);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_created_at ON complaints(created_at);
CREATE INDEX idx_complaints_number ON complaints(complaint_number);
CREATE INDEX idx_complaint_updates_complaint_id ON complaint_updates(complaint_id);
CREATE INDEX idx_complaint_attachments_complaint_id ON complaint_attachments(complaint_id);

-- Step 9: Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE complaint_updates ENABLE ROW LEVEL SECURITY;

-- Step 10: Create permissive policies
CREATE POLICY "allow_all_users" ON users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_complaints" ON complaints FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_attachments" ON complaint_attachments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_updates" ON complaint_updates FOR ALL USING (true) WITH CHECK (true);

-- Step 11: Grant permissions
GRANT ALL ON users TO anon, authenticated;
GRANT ALL ON complaints TO anon, authenticated;
GRANT ALL ON complaint_attachments TO anon, authenticated;
GRANT ALL ON complaint_updates TO anon, authenticated;

-- Step 12: Create sequence for complaint numbers (since we can't use SERIAL with UUID)
CREATE SEQUENCE IF NOT EXISTS complaint_number_seq START 1;
GRANT USAGE, SELECT ON complaint_number_seq TO anon, authenticated;

-- Step 13: Create functions for complaint number generation
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

-- Step 14: Create trigger
CREATE TRIGGER trigger_set_complaint_number
  BEFORE INSERT OR UPDATE ON complaints
  FOR EACH ROW
  EXECUTE FUNCTION set_complaint_number();

-- Success message
SELECT 'SUCCESS: Database created with UUID primary keys and foreign keys!' as result;
SELECT 'All foreign key type conflicts resolved!' as note;
