# Supabase Setup Guide

## Step 1: Get Your Supabase Credentials

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Create a new project or select an existing one
3. Go to **Settings** → **API**
4. Copy the following:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)

## Step 2: Update Configuration

Edit `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
}
```

## Step 3: Run Database Migrations

1. Go to your Supabase project
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `database.sql`
4. Run the migration

## Step 4: Create Storage Bucket

The app needs a storage bucket for vehicle photos and documents:

1. Go to your Supabase project
2. Navigate to **Storage** in the left sidebar
3. Click **New bucket**
4. Name it: `vehicle-documents`
5. Set it to **Public** (or configure RLS policies if you prefer private)
6. Click **Create bucket**

### Step 4a: Configure Storage RLS Policies (Required for Uploads)

If you're getting `403 Unauthorized` or `new row violates row-level security policy` errors when uploading files, you need to configure Storage policies:

1. Go to **Storage** → **Policies** in your Supabase dashboard
2. Select the `vehicle-documents` bucket
3. Click **New Policy**
4. Create an **INSERT** policy:
   - Policy name: `Allow authenticated uploads`
   - Allowed operation: `INSERT`
   - Policy definition: 
     ```sql
     (bucket_id = 'vehicle-documents'::text)
     ```
   - For roles: Select `authenticated` (or `anon` if using anonymous access)
   - Click **Review** and **Save policy**

5. Create a **SELECT** policy (for reading files):
   - Policy name: `Allow public reads`
   - Allowed operation: `SELECT`
   - Policy definition:
     ```sql
     (bucket_id = 'vehicle-documents'::text)
     ```
   - For roles: Select `anon` and `authenticated`
   - Click **Review** and **Save policy**

**Alternative: Disable RLS for Storage (Not Recommended for Production)**

If you want to disable RLS for the storage bucket (for development only):

1. Go to **Storage** → **Policies**
2. Select the `vehicle-documents` bucket
3. Toggle off **Enable RLS** (not recommended for production)

**Note**: If you don't create this bucket or configure policies, vehicle photos and document uploads will fail with `403 Unauthorized` errors, but the vehicle data will still be saved successfully.

## Step 5: Verify Connection

Run the app:
```bash
flutter run -d chrome
```

Check the console for:
- ✅ `Supabase initialized successfully` - Connection working
- ⚠️ `Supabase not configured - using mock data` - Using fallback data

## Database Schema

The app expects these tables:
- `hub` - Docking stations/franchises
- `vehicle` - Vehicles linked to hubs via `primary_hub_id`
- `maintenance_job` - Maintenance jobs
- `compliance_document` - Compliance documents
- `service_schedule` - Service schedules

## Vehicle-Hub Relationship

Vehicles are linked to their primary docking station (hub) via:
- `vehicle.primary_hub_id` → `hub.hub_id`

The app automatically fetches hub information when loading vehicles using Supabase joins.

## Testing Without Supabase

If Supabase is not configured, the app will:
- Use mock data automatically
- Show a warning in the console
- Still function for UI/UX testing

## Row Level Security (RLS)

If you enable RLS in Supabase, make sure to:
1. Create policies for the `vehicle` table
2. Allow SELECT for authenticated users
3. Allow INSERT/UPDATE for admin users

Example policy:
```sql
CREATE POLICY "Allow authenticated users to read vehicles"
ON vehicle FOR SELECT
TO authenticated
USING (true);
```


flutter config --enable-webflutter config --enable-web