-- Create service_items table for storing service details
CREATE TABLE IF NOT EXISTS public.service_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kanban_card_id UUID NOT NULL,
    name TEXT NOT NULL,
    quantity INTEGER DEFAULT 1,
    parts_cost DECIMAL(10, 2) DEFAULT 0,
    labour_cost DECIMAL(10, 2) DEFAULT 0,
    item_type TEXT NOT NULL CHECK (item_type IN ('periodic', 'bodyshop')),
    is_ice_specific BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (kanban_card_id) REFERENCES public.kanban_cards(id) ON DELETE CASCADE
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_service_items_kanban_card_id ON public.service_items(kanban_card_id);
CREATE INDEX IF NOT EXISTS idx_service_items_item_type ON public.service_items(item_type);

-- Add new columns to kanban_cards table if they don't exist
ALTER TABLE public.kanban_cards 
ADD COLUMN IF NOT EXISTS customer_name TEXT,
ADD COLUMN IF NOT EXISTS customer_phone TEXT,
ADD COLUMN IF NOT EXISTS customer_email TEXT,
ADD COLUMN IF NOT EXISTS gst_number TEXT,
ADD COLUMN IF NOT EXISTS vehicle_reg_number TEXT,
ADD COLUMN IF NOT EXISTS vehicle_make_model TEXT,
ADD COLUMN IF NOT EXISTS vehicle_year INTEGER,
ADD COLUMN IF NOT EXISTS vehicle_fuel_type TEXT DEFAULT 'EV';

-- Enable Row Level Security (RLS)
ALTER TABLE public.service_items ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for service_items (allow all operations for authenticated users)
CREATE POLICY "Enable all operations for authenticated users" ON public.service_items
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_service_items_updated_at ON public.service_items;
CREATE TRIGGER update_service_items_updated_at
    BEFORE UPDATE ON public.service_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions
GRANT ALL ON public.service_items TO authenticated;
GRANT ALL ON public.service_items TO anon;
