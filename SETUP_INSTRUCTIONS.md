# 🚀 TG Civic - Supabase Database Setup

Your application is now configured to work with your Supabase database. Follow these steps to complete the setup:

## 📋 Prerequisites

✅ **Supabase Project**: `pqhxsllzpirfpoeywhfy`  
✅ **Database URL**: `https://pqhxsllzpirfpoeywhfy.supabase.co`  
✅ **Connection String**: `postgresql://postgres:betterthanyourex07@db.pqhxsllzpirfpoeywhfy.supabase.co:5432/postgres`

## 🔑 Step 1: Get Your Supabase Anon Key

1. Go to your Supabase dashboard: https://supabase.com/dashboard/project/pqhxsllzpirfpoeywhfy
2. Navigate to **Settings** → **API**
3. Copy your **anon/public key** (it starts with `eyJ...`)

## ⚙️ Step 2: Configure Environment Variables

1. Create a `.env.local` file in your project root:

```bash
cp .env.example .env.local
```

2. Edit `.env.local` and add your actual anon key:

```env
VITE_SUPABASE_URL=https://pqhxsllzpirfpoeywhfy.supabase.co
VITE_SUPABASE_ANON_KEY=your_actual_anon_key_here
```

## 🗄️ Step 3: Set Up Database Schema

1. Go to your Supabase SQL Editor: https://supabase.com/dashboard/project/pqhxsllzpirfpoeywhfy/sql
2. Copy and paste the contents of `database-schema.sql`
3. Click **Run** to create the tables and policies

## 🧪 Step 4: Test the Connection

After setting up the environment variables and database schema:

1. Restart your development server:

```bash
npm run dev
```

2. Check the browser console for connection messages
3. Try registering a new user to test database functionality

## 👥 Default Test Accounts

The system will automatically create these accounts (if they don't exist):

| Role     | Email                | Password    | Access Level                |
| -------- | -------------------- | ----------- | --------------------------- |
| Admin    | admin@tgcivic.gov.in | admin123    | Full dashboard access       |
| Official | officer@ghmc.gov.in  | official123 | Complaint management        |
| Citizen  | rajesh@email.com     | citizen123  | Register & track complaints |

## 🔍 Troubleshooting

### Connection Issues

- Verify your anon key is correct
- Check that the `.env.local` file is in the root directory
- Ensure the Supabase project is not paused

### Database Schema Issues

- Make sure all SQL commands in `database-schema.sql` executed successfully
- Check the Supabase logs for any errors

### Authentication Issues

- Verify Row Level Security (RLS) policies are properly set
- Check that the users table was created correctly

## ✅ Verification Checklist

- [ ] Supabase anon key added to `.env.local`
- [ ] Database schema executed successfully
- [ ] Application starts without connection errors
- [ ] Can register new users
- [ ] Can login with existing accounts
- [ ] User data persists between sessions

## 🔧 Current Features

With the Supabase integration, your app now supports:

- ✅ **Real Database Storage**: User data stored in PostgreSQL
- ✅ **Secure Authentication**: Bcrypt password hashing
- ✅ **Session Management**: Persistent login sessions
- ✅ **Role-Based Access**: Admin, Official, Citizen roles
- ✅ **Profile Management**: Users can update their information
- ✅ **Data Validation**: Prevents duplicate emails/phones
- ✅ **Error Handling**: Comprehensive error messages

## 🚀 Next Steps

Once the basic authentication is working:

1. **Extend the schema** for complaints, departments, etc.
2. **Add real-time features** using Supabase subscriptions
3. **Implement file uploads** for complaint attachments
4. **Add email verification** using Supabase Auth
5. **Set up automated backups** in Supabase

Your TG Civic application is now ready for production use! 🎉
