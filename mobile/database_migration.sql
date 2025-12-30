-- Database Migration for Mobile App Features
-- Run this in your Supabase SQL Editor to create tables for mobile-specific features
-- Create mobile_daily_inventory table for daily inventory checks
CREATE TABLE IF NOT EXISTS mobile_daily_inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID REFERENCES crm_vehicles(vehicle_id) ON DELETE CASCADE,
  technician_id TEXT,
  check_date TIMESTAMP DEFAULT NOW(),
  status TEXT CHECK (status IN ('completed', 'pending', 'issues_found')),
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Create mobile_inventory_photos table for inventory photo tracking
CREATE TABLE IF NOT EXISTS mobile_inventory_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  inventory_id UUID REFERENCES mobile_daily_inventory(id) ON DELETE CASCADE,
  vehicle_id UUID REFERENCES crm_vehicles(vehicle_id) ON DELETE CASCADE,
  category TEXT CHECK (category IN ('ext_front', 'ext_rear', 'ext_left', 'ext_right', 'dents', 'interior', 'dikki', 'tools', 'valuables', 'other')),
  photo_url TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Ensure check constraint is up to date for existing tables
DO $$ 
BEGIN
    ALTER TABLE mobile_inventory_photos DROP CONSTRAINT IF EXISTS mobile_inventory_photos_category_check;
    ALTER TABLE mobile_inventory_photos ADD CONSTRAINT mobile_inventory_photos_category_check 
        CHECK (category IN ('ext_front', 'ext_rear', 'ext_left', 'ext_right', 'dents', 'interior', 'dikki', 'tools', 'valuables', 'other'));
EXCEPTION
    WHEN undefined_table THEN
        NULL;
END $$;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_mobile_daily_inventory_vehicle_id ON mobile_daily_inventory(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_mobile_daily_inventory_check_date ON mobile_daily_inventory(check_date DESC);
CREATE INDEX IF NOT EXISTS idx_mobile_inventory_photos_vehicle_id ON mobile_inventory_photos(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_mobile_inventory_photos_inventory_id ON mobile_inventory_photos(inventory_id);

-- Enable Row Level Security (RLS)
ALTER TABLE mobile_daily_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_inventory_photos ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for mobile_daily_inventory
DROP POLICY IF EXISTS "Allow authenticated users to read daily inventory" ON mobile_daily_inventory;
DROP POLICY IF EXISTS "Allow public read on daily inventory" ON mobile_daily_inventory;
CREATE POLICY "Allow public read on daily inventory"
ON mobile_daily_inventory FOR SELECT
TO authenticated, anon
USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to insert daily inventory" ON mobile_daily_inventory;
DROP POLICY IF EXISTS "Allow public insert on daily inventory" ON mobile_daily_inventory;
CREATE POLICY "Allow public insert on daily inventory"
ON mobile_daily_inventory FOR INSERT
TO authenticated, anon
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated users to update daily inventory" ON mobile_daily_inventory;
DROP POLICY IF EXISTS "Allow public update on daily inventory" ON mobile_daily_inventory;
CREATE POLICY "Allow public update on daily inventory"
ON mobile_daily_inventory FOR UPDATE
TO authenticated, anon
USING (true);

-- Create RLS policies for mobile_inventory_photos
DROP POLICY IF EXISTS "Allow authenticated users to read inventory photos" ON mobile_inventory_photos;
DROP POLICY IF EXISTS "Allow public read on inventory photos" ON mobile_inventory_photos;
CREATE POLICY "Allow public read on inventory photos"
ON mobile_inventory_photos FOR SELECT
TO authenticated, anon
USING (true);

DROP POLICY IF EXISTS "Allow authenticated users to insert inventory photos" ON mobile_inventory_photos;
DROP POLICY IF EXISTS "Allow public insert on inventory photos" ON mobile_inventory_photos;
CREATE POLICY "Allow public insert on inventory photos"
ON mobile_inventory_photos FOR INSERT
TO authenticated, anon
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated users to delete inventory photos" ON mobile_inventory_photos;
DROP POLICY IF EXISTS "Allow public delete on inventory photos" ON mobile_inventory_photos;
CREATE POLICY "Allow public delete on inventory photos"
ON mobile_inventory_photos FOR DELETE
TO authenticated, anon
USING (true);

-- ==========================================
-- STORAGE SETUP (Run this in SQL Editor)
-- ==========================================

-- 1. Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('vehicle-documents', 'vehicle-documents', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Set up RLS for Storage (INSERT POLICY)
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow public uploads" ON storage.objects;
CREATE POLICY "Allow public uploads"
ON storage.objects FOR INSERT
TO authenticated, anon
WITH CHECK (bucket_id = 'vehicle-documents');

-- 3. Set up RLS for Storage (SELECT POLICY)
DROP POLICY IF EXISTS "Allow public reads" ON storage.objects;
CREATE POLICY "Allow public reads"
ON storage.objects FOR SELECT
TO authenticated, anon
USING (bucket_id = 'vehicle-documents');

-- 4. Set up RLS for Storage (DELETE POLICY - Optional)
DROP POLICY IF EXISTS "Allow authenticated deletes" ON storage.objects;
CREATE POLICY "Allow authenticated deletes"
ON storage.objects FOR DELETE
TO authenticated, anon
USING (bucket_id = 'vehicle-documents');

-- Add helpful comments
COMMENT ON TABLE mobile_daily_inventory IS 'Stores daily inventory check records from mobile app';
COMMENT ON TABLE mobile_inventory_photos IS 'Stores inventory photo URLs from mobile app';

-- Optional: Create a function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for mobile_daily_inventory
DROP TRIGGER IF EXISTS update_mobile_daily_inventory_updated_at ON mobile_daily_inventory;
CREATE TRIGGER update_mobile_daily_inventory_updated_at
    BEFORE UPDATE ON mobile_daily_inventory
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ==========================================
-- UNIVERSAL SCHEMA SYNC (Run after code update)
-- ==========================================

-- 1. Ensure crm_vehicles has the base columns (Resilient to id vs vehicle_id)
DO $$ 
BEGIN
    -- If 'id' exists but 'vehicle_id' does not, add vehicle_id as a generated alias/column
    -- or just ensure our queries (which now use 'id') work.
    -- For safety, we will just make sure all summary columns exist.
    ALTER TABLE crm_vehicles ADD COLUMN IF NOT EXISTS is_vehicle_in BOOLEAN DEFAULT true;
    ALTER TABLE crm_vehicles ADD COLUMN IF NOT EXISTS to_dos JSONB DEFAULT '[]';
    ALTER TABLE crm_vehicles ADD COLUMN IF NOT EXISTS last_service_date TIMESTAMP;
    ALTER TABLE crm_vehicles ADD COLUMN IF NOT EXISTS last_service_type TEXT;
    ALTER TABLE crm_vehicles ADD COLUMN IF NOT EXISTS service_attention BOOLEAN DEFAULT false;
    ALTER TABLE crm_vehicles ADD COLUMN IF NOT EXISTS last_charge_type TEXT DEFAULT 'AC';
    ALTER TABLE crm_vehicles ADD COLUMN IF NOT EXISTS charging_health TEXT DEFAULT 'Good';
    ALTER TABLE crm_vehicles ADD COLUMN IF NOT EXISTS daily_checks JSONB DEFAULT '{}';
    ALTER TABLE crm_vehicles ADD COLUMN IF NOT EXISTS last_full_scan JSONB DEFAULT '{}';
    ALTER TABLE crm_vehicles ADD COLUMN IF NOT EXISTS inventory_photo_count INTEGER DEFAULT 0;
    ALTER TABLE crm_vehicles ADD COLUMN IF NOT EXISTS last_inventory_time TIMESTAMP;
END $$;

-- 2. Reset and Fix RLS Policies for Visibility
ALTER TABLE crm_vehicles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated read on crm_vehicles" ON crm_vehicles;
DROP POLICY IF EXISTS "Allow public read on crm_vehicles" ON crm_vehicles;
CREATE POLICY "Allow public read on crm_vehicles"
ON crm_vehicles FOR SELECT
TO authenticated, anon
USING (true);

DROP POLICY IF EXISTS "Allow authenticated update on crm_vehicles" ON crm_vehicles;
DROP POLICY IF EXISTS "Allow public update on crm_vehicles" ON crm_vehicles;
CREATE POLICY "Allow public update on crm_vehicles"
ON crm_vehicles FOR UPDATE
TO authenticated, anon
USING (true)
WITH CHECK (true);

-- 3. Success Message
DO $$
BEGIN
    RAISE NOTICE 'Universal Schema Fix Applied Successfully!';
END $$;
