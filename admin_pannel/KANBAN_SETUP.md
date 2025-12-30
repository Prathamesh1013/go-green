# Kanban Board Setup

## Quick Setup (5 minutes)

### Step 1: Create the Database Table

1. Go to your Supabase dashboard: https://app.supabase.com/project/hhgxctansltxlrhzunji/sql
2. Click **SQL Editor** → **New Query**
3. Copy and paste this SQL:

```sql
CREATE TABLE IF NOT EXISTS kanban_cards (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  column_status TEXT NOT NULL,
  position INTEGER DEFAULT 0,
  due_date TIMESTAMP,
  vehicle_id UUID REFERENCES crm_vehicles(vehicle_id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_kanban_column_status ON kanban_cards(column_status);
CREATE INDEX IF NOT EXISTS idx_kanban_position ON kanban_cards(position);

-- Sample data
INSERT INTO kanban_cards (title, description, column_status, position, due_date) VALUES
('MH15JC0055', 'Battery replacement needed', 'kalyan_tp', 0, '2025-01-15'),
('GG Protech - Tata Tigor', 'Regular maintenance', 'ongoing_dealership', 0, '2025-01-10'),
('TATA TIGOR XPRESS-T XM', 'Tire check required', 'non_workshop_active', 0, '2025-01-20');
```

4. Click **Run** (or press Ctrl+Enter)
5. You should see "Success"

### Step 2: Restart Your App

```bash
# Stop the current app (press 'q' in terminal)
# Then run:
flutter run -d chrome
```

### Step 3: View the Kanban Board

Navigate to the Dashboard page and you'll see the Kanban board with 5 columns:
- Kalyan TP
- Ongoing Dealership  
- Non Workshop Active
- Payment Pending
- Completed

## Features

✅ Clean white UI matching Analytics dashboard
✅ Add new cards with title, description, and due date
✅ Delete cards
✅ View cards organized by status
✅ Fully database-connected

## Column Status Values

Use these values for `column_status`:
- `kalyan_tp`
- `ongoing_dealership`
- `non_workshop_active`
- `payment_pending`
- `completed`
