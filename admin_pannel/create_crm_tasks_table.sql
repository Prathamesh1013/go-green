-- Create crm_tasks table for storing interaction tasks
CREATE TABLE IF NOT EXISTS public.crm_tasks (
  task_id uuid NOT NULL DEFAULT gen_random_uuid(),
  interaction_id uuid NOT NULL,
  category character varying NOT NULL DEFAULT 'Other',
  task_type character varying NOT NULL,
  quantity integer NOT NULL DEFAULT 1,
  description text NOT NULL,
  is_completed boolean NOT NULL DEFAULT false,
  vendor_name character varying,
  purchase_price numeric DEFAULT 0,
  sell_price numeric DEFAULT 0,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT crm_tasks_pkey PRIMARY KEY (task_id),
  CONSTRAINT crm_tasks_interaction_id_fkey FOREIGN KEY (interaction_id) REFERENCES public.crm_interactions(interaction_id) ON DELETE CASCADE
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_crm_tasks_interaction_id ON public.crm_tasks(interaction_id);
CREATE INDEX IF NOT EXISTS idx_crm_tasks_task_type ON public.crm_tasks(task_type);

-- Enable RLS (Row Level Security) if needed
ALTER TABLE public.crm_tasks ENABLE ROW LEVEL SECURITY;

-- Create policy to allow all operations (adjust as needed for your security requirements)
CREATE POLICY "Allow all operations on crm_tasks" ON public.crm_tasks
  FOR ALL
  USING (true)
  WITH CHECK (true);



