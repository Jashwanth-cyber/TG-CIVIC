-- TG Civic Database Schema
-- Copy and paste this ENTIRE script into your Supabase SQL Editor and run it

-- Create users table
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow public registration" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;

-- Create policies for RLS
-- Allow public registration (insert)
CREATE POLICY "Allow public registration" ON users
  FOR INSERT WITH CHECK (true);

-- Users can read their own data
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (true); -- Allow reading for now, can be restricted later

-- Users can update their own data
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (true); -- Allow updates for now, can be restricted later

-- Grant necessary permissions
GRANT ALL ON users TO authenticated;
GRANT ALL ON users TO anon;
GRANT USAGE, SELECT ON SEQUENCE users_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE users_id_seq TO authenticated;

-- Verify the table was created
SELECT 'Users table created successfully!' as message;
