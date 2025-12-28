-- Kanban Board Table
-- Run this in your Supabase SQL Editor: https://app.supabase.com/project/hhgxctansltxlrhzunji/sql

CREATE TABLE IF NOT EXISTS kanban_cards (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  column_status TEXT NOT NULL,
  sub_category TEXT, -- For Upcoming: overdue, today, tomorrow, 7_days
  position INTEGER DEFAULT 0,
  due_date TIMESTAMP,
  vehicle_id UUID REFERENCES crm_vehicles(vehicle_id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_kanban_column_status ON kanban_cards(column_status);
CREATE INDEX IF NOT EXISTS idx_kanban_position ON kanban_cards(position);
CREATE INDEX IF NOT EXISTS idx_kanban_sub_category ON kanban_cards(sub_category);

-- Insert all cards from the Kanban board

-- Upcoming column - Overdue (0)
-- (No cards shown in image)

-- Upcoming column - Today (0)
-- (No cards shown in image)

-- Upcoming column - Tomorrow (0)
-- (No cards shown in image)

-- Upcoming column - 7+ Days (0)
-- (No cards shown in image)

-- Upcoming (Non registered) column
-- (No cards shown in image)

-- Nashik TP column (17 cards shown in image)
INSERT INTO kanban_cards (title, description, column_status, position, due_date) VALUES
('GG Protech', 'TATA Tigor - MH15JC0057', 'nashik_tp', 0, '2025-12-23 23:14:00'),
('GG Protech', 'Tara - MH15JC0054', 'nashik_tp', 1, '2025-12-23 23:14:00'),
('GG Protech', 'Tigor EV - MH15JCD689', 'nashik_tp', 2, '2025-12-23 23:14:00'),
('GG Protech', 'TATA TIGOR XPRESS-T XM - MH15JCD688', 'nashik_tp', 3, '2025-12-22 01:26:00'),
('GG Protech', 'TATA TIGOR XPRESS-T XM - MH15JCD687', 'nashik_tp', 4, '2025-12-21 06:34:00'),
('GG Protech', 'TATA XPRESS-T XM - Kailashnagar', 'nashik_tp', 5, '2025-12-21 06:34:00');

-- Kalyan TP column (0)
-- (No vehicles shown)

-- Ongoing Dealership column (0)
-- (No vehicles shown)
