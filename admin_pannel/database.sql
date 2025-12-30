-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.charging_session (
  charge_session_id uuid NOT NULL,
  vehicle_id uuid NOT NULL,
  start_time timestamp with time zone NOT NULL,
  end_time timestamp with time zone,
  energy_kwh numeric,
  charge_level_start integer,
  charge_level_end integer,
  location_id uuid,
  session_type text DEFAULT 'depot'::text CHECK (session_type = ANY (ARRAY['depot'::text, 'public_charger'::text, 'emergency_charge'::text])),
  cost numeric,
  created_date timestamp with time zone DEFAULT now(),
  CONSTRAINT charging_session_pkey PRIMARY KEY (charge_session_id),
  CONSTRAINT charging_session_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicle(vehicle_id),
  CONSTRAINT charging_session_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.hub(hub_id)
);
CREATE TABLE public.compliance_document (
  document_id uuid NOT NULL,
  vehicle_id uuid NOT NULL,
  doc_type text NOT NULL CHECK (doc_type = ANY (ARRAY['insurance'::text, 'registration'::text, 'PUC'::text, 'permit'::text, 'fitness'::text, 'warranty'::text, 'roadtax'::text])),
  issuer text,
  policy_number text,
  issue_date date,
  expiry_date date,
  days_until_expiry integer,
  renewal_cost numeric,
  scan_url text,
  status text DEFAULT 'valid'::text CHECK (status = ANY (ARRAY['valid'::text, 'expiring_soon'::text, 'expired'::text])),
  created_date timestamp with time zone DEFAULT now(),
  CONSTRAINT compliance_document_pkey PRIMARY KEY (document_id),
  CONSTRAINT compliance_document_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicle(vehicle_id)
);
CREATE TABLE public.crm_customers (
  customer_id uuid NOT NULL DEFAULT gen_random_uuid(),
  full_name character varying NOT NULL,
  mobile_number character varying NOT NULL,
  email_id character varying NOT NULL,
  address text NOT NULL,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT crm_customers_pkey PRIMARY KEY (customer_id)
);
CREATE TABLE public.crm_interactions (
  interaction_id uuid NOT NULL DEFAULT gen_random_uuid(),
  vehicle_id uuid NOT NULL,
  interaction_number character varying NOT NULL UNIQUE,
  interaction_status character varying NOT NULL,
  current_odometer_reading integer NOT NULL,
  pickup_date_time timestamp with time zone NOT NULL,
  vendor_name character varying NOT NULL,
  primary_job character varying NOT NULL,
  customer_note text NOT NULL,
  purchase_price numeric NOT NULL,
  sell_price numeric NOT NULL,
  profit numeric,
  customer_payment_status character varying NOT NULL,
  vendor_payment_status character varying NOT NULL,
  total_amount numeric NOT NULL,
  delivery_date date NOT NULL,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT crm_interactions_pkey PRIMARY KEY (interaction_id),
  CONSTRAINT crm_interactions_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.crm_vehicles(vehicle_id)
);
CREATE TABLE public.crm_non_workshop_tasks (
  task_id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  due_date timestamp with time zone,
  status text DEFAULT 'active'::text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT crm_non_workshop_tasks_pkey PRIMARY KEY (task_id)
);
CREATE TABLE public.crm_upcoming_non_registered_tasks (
  task_id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  due_date timestamp with time zone,
  status text DEFAULT 'active'::text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT crm_upcoming_non_registered_tasks_pkey PRIMARY KEY (task_id)
);
CREATE TABLE public.crm_vehicles (
  vehicle_id uuid NOT NULL DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL,
  make_model_year character varying NOT NULL,
  registration_number character varying NOT NULL UNIQUE,
  avg_monthly_run integer NOT NULL DEFAULT 1000,
  workshop_preference character varying,
  fuel_type character varying NOT NULL,
  year_of_registration integer NOT NULL,
  last_service_date date,
  next_service_date date,
  insurance_expiry date,
  puc_expiry date,
  latest_odometer_reading integer,
  pending_jobs jsonb DEFAULT '[]'::jsonb,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  warranty_status text,
  last_service_status text,
  CONSTRAINT crm_vehicles_pkey PRIMARY KEY (vehicle_id),
  CONSTRAINT crm_vehicles_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.crm_customers(customer_id)
);
CREATE TABLE public.daily_check (
  checklist_id uuid NOT NULL,
  vehicle_id uuid NOT NULL,
  date date NOT NULL,
  check_type text NOT NULL CHECK (check_type = ANY (ARRAY['daily_clean_car'::text, 'overall_inspection'::text, 'PDI'::text, 'tyre_pressure'::text, 'station_checkin'::text, 'station_checkout'::text])),
  status text NOT NULL CHECK (status = ANY (ARRAY['completed'::text, 'missed'::text, 'failed'::text])),
  completion_time timestamp with time zone,
  driver_id uuid,
  hub_id uuid,
  remarks text,
  issues_found ARRAY,
  created_date timestamp with time zone DEFAULT now(),
  CONSTRAINT daily_check_pkey PRIMARY KEY (checklist_id),
  CONSTRAINT daily_check_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicle(vehicle_id),
  CONSTRAINT daily_check_hub_id_fkey FOREIGN KEY (hub_id) REFERENCES public.hub(hub_id)
);
CREATE TABLE public.hub (
  hub_id uuid NOT NULL,
  name text NOT NULL,
  city text,
  state text,
  address text,
  created_date timestamp with time zone DEFAULT now(),
  CONSTRAINT hub_pkey PRIMARY KEY (hub_id)
);
CREATE TABLE public.job_activity (
  activity_id uuid NOT NULL,
  job_id uuid NOT NULL,
  activity_type text NOT NULL CHECK (activity_type = ANY (ARRAY['status_change'::text, 'note_added'::text, 'photo_uploaded'::text, 'cost_updated'::text, 'technician_assigned'::text, 'customer_contacted'::text, 'parts_ordered'::text, 'completion'::text])),
  action_by uuid,
  old_value text,
  new_value text,
  description text,
  created_date timestamp with time zone DEFAULT now(),
  CONSTRAINT job_activity_pkey PRIMARY KEY (activity_id),
  CONSTRAINT job_activity_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.maintenance_job(job_id),
  CONSTRAINT job_activity_action_by_fkey FOREIGN KEY (action_by) REFERENCES public.technician(technician_id)
);
CREATE TABLE public.job_media (
  media_id uuid NOT NULL,
  job_id uuid NOT NULL,
  media_type text NOT NULL CHECK (media_type = ANY (ARRAY['photo_before'::text, 'photo_after'::text, 'invoice'::text, 'receipt'::text, 'report'::text, 'other'::text])),
  file_url text NOT NULL,
  file_name text,
  file_size integer,
  mime_type text,
  caption text,
  uploaded_by uuid,
  uploaded_date timestamp with time zone DEFAULT now(),
  created_date timestamp with time zone DEFAULT now(),
  CONSTRAINT job_media_pkey PRIMARY KEY (media_id),
  CONSTRAINT job_media_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.maintenance_job(job_id),
  CONSTRAINT job_media_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.technician(technician_id)
);
CREATE TABLE public.job_parts (
  job_part_id uuid NOT NULL,
  job_id uuid NOT NULL,
  part_id uuid,
  quantity integer NOT NULL,
  unit_cost numeric,
  total_cost numeric,
  serial_number text,
  notes text,
  created_date timestamp with time zone DEFAULT now(),
  CONSTRAINT job_parts_pkey PRIMARY KEY (job_part_id),
  CONSTRAINT job_parts_part_id_fkey FOREIGN KEY (part_id) REFERENCES public.part(part_id),
  CONSTRAINT job_parts_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.maintenance_job(job_id)
);
CREATE TABLE public.maintenance_job (
  job_id uuid NOT NULL,
  vehicle_id uuid NOT NULL,
  job_type text NOT NULL,
  job_category text NOT NULL CHECK (job_category = ANY (ARRAY['scheduled'::text, 'breakdown'::text, 'warranty'::text, 'RSA'::text, 'PDI'::text])),
  diagnosis_date timestamp with time zone NOT NULL,
  service_center_id uuid,
  assigned_to uuid,
  status text DEFAULT 'pending_diagnosis'::text CHECK (status = ANY (ARRAY['pending_diagnosis'::text, 'in_progress'::text, 'completed'::text, 'on_hold'::text, 'cancelled'::text])),
  due_date date,
  completion_date timestamp with time zone,
  total_cost numeric,
  parts_cost numeric,
  labour_cost numeric,
  warranty_flag boolean DEFAULT false,
  warranty_claim_amount numeric,
  diagnosis_notes text,
  repair_notes text,
  customer_notes text,
  repeat_flag boolean DEFAULT false,
  repeat_count integer DEFAULT 0,
  created_date timestamp with time zone DEFAULT now(),
  updated_date timestamp with time zone DEFAULT now(),
  CONSTRAINT maintenance_job_pkey PRIMARY KEY (job_id),
  CONSTRAINT maintenance_job_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicle(vehicle_id),
  CONSTRAINT maintenance_job_service_center_id_fkey FOREIGN KEY (service_center_id) REFERENCES public.service_center(service_center_id),
  CONSTRAINT maintenance_job_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.technician(technician_id)
);
CREATE TABLE public.part (
  part_id uuid NOT NULL,
  part_name text NOT NULL,
  category text,
  unit_cost numeric,
  stock_qty integer,
  min_stock_level integer,
  supplier_id uuid,
  last_replenished date,
  annual_usage integer,
  created_date timestamp with time zone DEFAULT now(),
  CONSTRAINT part_pkey PRIMARY KEY (part_id)
);
CREATE TABLE public.service_center (
  service_center_id uuid NOT NULL,
  name text NOT NULL,
  hub_id uuid,
  contact_name text,
  contact_phone text,
  address text,
  created_date timestamp with time zone DEFAULT now(),
  CONSTRAINT service_center_pkey PRIMARY KEY (service_center_id),
  CONSTRAINT service_center_hub_id_fkey FOREIGN KEY (hub_id) REFERENCES public.hub(hub_id)
);
CREATE TABLE public.service_schedule (
  service_id uuid NOT NULL,
  vehicle_id uuid NOT NULL,
  service_type text NOT NULL CHECK (service_type = ANY (ARRAY['minor_service'::text, 'major_service'::text, 'annual_check'::text, 'PDI'::text, 'taxi_fitness'::text])),
  due_km integer,
  due_date date,
  completed_km integer,
  completed_date timestamp with time zone,
  overdue_days integer,
  priority text DEFAULT 'medium'::text CHECK (priority = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text])),
  recommended_parts ARRAY,
  created_date timestamp with time zone DEFAULT now(),
  CONSTRAINT service_schedule_pkey PRIMARY KEY (service_id),
  CONSTRAINT service_schedule_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicle(vehicle_id)
);
CREATE TABLE public.technician (
  technician_id uuid NOT NULL,
  name text NOT NULL,
  email text,
  phone text,
  hub_id uuid,
  specialization text,
  status text DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'inactive'::text, 'on_leave'::text])),
  created_date timestamp with time zone DEFAULT now(),
  CONSTRAINT technician_pkey PRIMARY KEY (technician_id),
  CONSTRAINT technician_hub_id_fkey FOREIGN KEY (hub_id) REFERENCES public.hub(hub_id)
);
CREATE TABLE public.vehicle (
  vehicle_id uuid NOT NULL,
  vehicle_number text NOT NULL UNIQUE,
  make text,
  model text,
  variant text,
  fuel_type text CHECK (fuel_type = ANY (ARRAY['ICE'::text, 'EV'::text, 'Hybrid'::text, 'CNG'::text])),
  year_of_manufacture integer,
  telematics_id text,
  status text DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'inactive'::text, 'scrapped'::text, 'trial'::text])),
  owner_type text DEFAULT 'client_owned'::text CHECK (owner_type = ANY (ARRAY['client_owned'::text, 'leased'::text])),
  primary_hub_id uuid,
  created_date timestamp with time zone DEFAULT now(),
  updated_date timestamp with time zone DEFAULT now(),
  odometer_current integer,
  avg_km_per_day numeric,
  avg_trips_per_day numeric,
  last_trip_date date,
  last_active_date date,
  health_state text CHECK (health_state = ANY (ARRAY['healthy'::text, 'attention'::text, 'critical'::text])),
  total_downtime_days integer,
  CONSTRAINT vehicle_pkey PRIMARY KEY (vehicle_id),
  CONSTRAINT vehicle_primary_hub_id_fkey FOREIGN KEY (primary_hub_id) REFERENCES public.hub(hub_id)
);