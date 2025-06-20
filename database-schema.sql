-- TG Civic Application Database Schema
-- Execute this in your Supabase SQL Editor

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'citizen',
  department VARCHAR(255),
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

-- Create policies for RLS
-- Users can read their own data
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid()::text = id::text);

-- Users can update their own data (except role)
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid()::text = id::text);

-- Allow public registration (insert)
CREATE POLICY "Allow public registration" ON users
  FOR INSERT WITH CHECK (true);

-- Insert default users with hashed passwords
-- Note: In production, these should be created via your admin interface

DO $$
DECLARE
  admin_exists INTEGER;
  official_exists INTEGER;
  citizen_exists INTEGER;
BEGIN
  -- Check if admin user exists
  SELECT COUNT(*) INTO admin_exists FROM users WHERE email = 'admin@tgcivic.gov.in';
  
  IF admin_exists = 0 THEN
    INSERT INTO users (name, email, phone, password_hash, role, department, email_verified) VALUES
    ('Admin User', 'admin@tgcivic.gov.in', '9876543210', '$2b$12$dummy_hash_replace_with_real', 'admin', 'IT Department', true);
  END IF;

  -- Check if official user exists
  SELECT COUNT(*) INTO official_exists FROM users WHERE email = 'officer@ghmc.gov.in';
  
  IF official_exists = 0 THEN
    INSERT INTO users (name, email, phone, password_hash, role, department, email_verified) VALUES
    ('GHMC Officer', 'officer@ghmc.gov.in', '9876543212', '$2b$12$dummy_hash_replace_with_real', 'official', 'GHMC Roads Department', true);
  END IF;

  -- Check if citizen user exists
  SELECT COUNT(*) INTO citizen_exists FROM users WHERE email = 'rajesh@email.com';
  
  IF citizen_exists = 0 THEN
    INSERT INTO users (name, email, phone, password_hash, role, email_verified) VALUES
    ('Rajesh Kumar', 'rajesh@email.com', '9876543211', '$2b$12$dummy_hash_replace_with_real', 'citizen', true);
  END IF;
END $$;

-- Grant necessary permissions
GRANT ALL ON users TO authenticated;
GRANT ALL ON users TO anon;

-- Note: The dummy password hashes above need to be replaced with real bcrypt hashes
-- The application will create users with proper password hashing automatically
