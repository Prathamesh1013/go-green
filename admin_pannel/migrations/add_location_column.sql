-- Migration: Add location column to kanban_cards table
-- Purpose: Store dealership location (nashik, pune_station1, pune_station2)
-- Date: 2025-12-30

-- Add location column
ALTER TABLE public.kanban_cards 
ADD COLUMN IF NOT EXISTS location VARCHAR(50);

-- Add comment
COMMENT ON COLUMN public.kanban_cards.location IS 'Dealership location for cards in upcoming_non_registered column (nashik, pune_station1, pune_station2)';
