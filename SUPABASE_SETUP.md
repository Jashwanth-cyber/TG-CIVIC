# Supabase Integration Setup

## Current Status

The application is currently using an in-memory database simulation that works in the browser. To connect to your actual Supabase database, follow these steps:

## 1. Get your Supabase Project Keys

Visit your Supabase project dashboard at: https://supabase.com/dashboard/project/pqhxsllzpirfpoeywhfy

You'll need:

- **Project URL**: `https://pqhxsllzpirfpoeywhfy.supabase.co`
- **Anon Key**: Found in Settings > API

## 2. Update the Database Configuration

Replace the mock implementation in `src/lib/database.ts` with:

```typescript
import { createClient } from "@supabase/supabase-js";

const supabaseUrl = "https://pqhxsllzpirfpoeywhfy.supabase.co";
const supabaseAnonKey = "YOUR_ACTUAL_ANON_KEY_HERE";

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
```

## 3. Create the Users Table in Supabase

Run this SQL in your Supabase SQL Editor:

```sql
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

-- Insert default users
INSERT INTO users (name, email, phone, password_hash, role, department, email_verified) VALUES
('Admin User', 'admin@tgcivic.gov.in', '9876543210', '$2b$12$hash_for_admin123', 'admin', 'IT Department', true),
('GHMC Officer', 'officer@ghmc.gov.in', '9876543212', '$2b$12$hash_for_official123', 'official', 'GHMC Roads Department', true),
('Rajesh Kumar', 'rajesh@email.com', '9876543211', '$2b$12$hash_for_citizen123', 'citizen', NULL, true);
```

## 4. Update Authentication Functions

Replace the query functions in `src/lib/auth.ts` to use Supabase client methods:

```typescript
import { supabase } from "./database";

export const registerUser = async (
  userData: RegisterData,
): Promise<User | null> => {
  // Use supabase.from('users').insert()
};

export const loginUser = async (loginData: LoginData): Promise<User | null> => {
  // Use supabase.from('users').select().eq()
};
```

## 5. Environment Variables (Optional)

For better security, store your Supabase keys in environment variables:

Create `.env.local`:

```
VITE_SUPABASE_URL=https://pqhxsllzpirfpoeywhfy.supabase.co
VITE_SUPABASE_ANON_KEY=your_actual_anon_key
```

## Current Working Features

Even with the mock database, all features work:

- ✅ User registration
- ✅ User login with password verification
- ✅ Session persistence
- ✅ Role-based access (admin, citizen, official)
- ✅ Profile management
- ✅ Default demo accounts

## Demo Accounts (Currently Available)

- **Admin**: admin@tgcivic.gov.in / admin123
- **Citizen**: rajesh@email.com / citizen123
- **Official**: officer@ghmc.gov.in / official123

The application is fully functional and ready for testing!
