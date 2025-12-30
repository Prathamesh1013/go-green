-- Migration script to support custom job types in service_items table
-- Run this script in your Supabase SQL editor to allow custom job types

-- Step 1: Drop the existing CHECK constraint
ALTER TABLE public.service_items 
DROP CONSTRAINT IF EXISTS service_items_item_type_check;

-- Step 2: The item_type column will now accept any TEXT value
-- This allows custom job names like 'Clutch Overhaul', 'AC Service', etc.
-- No additional constraint needed as TEXT already allows any string value

-- Note: Existing data with 'periodic' and 'bodyshop' will continue to work
-- New custom jobs will use their job name as the item_type value

