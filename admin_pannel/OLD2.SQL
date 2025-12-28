-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.customers (
  customer_id uuid NOT NULL DEFAULT gen_random_uuid(),
  full_name character varying NOT NULL,
  mobile_number character varying NOT NULL,
  email_id character varying NOT NULL,
  address text NOT NULL,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT customers_pkey PRIMARY KEY (customer_id)
);
CREATE TABLE public.interactions (
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
  profit numeric DEFAULT (sell_price - purchase_price),
  customer_payment_status character varying NOT NULL,
  vendor_payment_status character varying NOT NULL,
  total_amount numeric NOT NULL,
  delivery_date date NOT NULL,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT interactions_pkey PRIMARY KEY (interaction_id),
  CONSTRAINT interactions_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(vehicle_id)
);
CREATE TABLE public.non_workshop_tasks (
  task_id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  due_date timestamp with time zone,
  status text DEFAULT 'active'::text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT non_workshop_tasks_pkey PRIMARY KEY (task_id)
);
CREATE TABLE public.tasks (
  task_id uuid NOT NULL DEFAULT gen_random_uuid(),
  interaction_id uuid NOT NULL,
  category USER-DEFINED NOT NULL DEFAULT 'General'::task_category,
  task_type USER-DEFINED NOT NULL,
  quantity integer NOT NULL DEFAULT 1,
  description text NOT NULL,
  is_completed boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  vendor_name character varying,
  purchase_price numeric DEFAULT 0,
  sell_price numeric DEFAULT 0,
  CONSTRAINT tasks_pkey PRIMARY KEY (task_id),
  CONSTRAINT tasks_interaction_id_fkey FOREIGN KEY (interaction_id) REFERENCES public.interactions(interaction_id)
);
CREATE TABLE public.upcoming_non_registered_tasks (
  task_id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  due_date timestamp with time zone,
  status text DEFAULT 'active'::text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT upcoming_non_registered_tasks_pkey PRIMARY KEY (task_id)
);
CREATE TABLE public.vehicles (
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
  CONSTRAINT vehicles_pkey PRIMARY KEY (vehicle_id),
  CONSTRAINT vehicles_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id)
);