drop table if exists public.schedule_shifts CASCADE;
drop table if exists public.employee_schedules CASCADE;
DROP TABLE IF EXISTS public.schedules CASCADE;
drop table if exists public.shifts CASCADE;
drop table if exists public.employee CASCADE;
drop table if exists public.employee_public CASCADE;
drop table if exists public.employee_public_pending CASCADE;
drop table if exists public.organizations CASCADE;
drop table if exists public.job_positions CASCADE;
drop table if exists public.job_levels CASCADE;
drop table if exists public.employee_private CASCADE;


CREATE TABLE public.schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar NOT NULL,
  created_at timestamp DEFAULT now()
);

CREATE TABLE public.shifts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  is_working_day boolean NOT NULL DEFAULT true,
  code varchar, 
  color varchar,
  created_at timestamp DEFAULT now()
);

CREATE TABLE public.schedule_shifts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_id uuid NOT NULL REFERENCES public.schedules(id) ON DELETE CASCADE,
  shift_id uuid NOT NULL REFERENCES public.shifts(id) ON DELETE CASCADE,
  tanggal date NOT NULL,
  created_at timestamp DEFAULT now(),
  CONSTRAINT unique_schedule_shift_day UNIQUE (schedule_id, shift_id, tanggal)
);

CREATE TABLE PUBLIC.employee_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  schedule_id uuid NOT NULL REFERENCES public.schedules(id) ON DELETE CASCADE,
  created_at timestamp DEFAULT now(),
  CONSTRAINT unique_employee UNIQUE (auth_id)
);

CREATE TABLE public.employee_public(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name varchar NOT NULL,
  last_name varchar,
  place_of_birth varchar,
  date_of_birth date,
  gender varchar,
  martial_status varchar,
  blood_type varchar,
  religion varchar,
  nik varchar,
  created_at timestamp DEFAULT now()
);

CREATE TABLE public.employee_public_pending(
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name varchar NOT NULL,
  last_name varchar,
  place_of_birth varchar,
  date_of_birth date,
  gender varchar,
  martial_status varchar,
  blood_type varchar,
  religion varchar,
  nik varchar,
  created_at timestamp DEFAULT now()
);

CREATE TABLE public.organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar NOT NULL,
  created_at timestamp DEFAULT now()
);

CREATE TABLE public.job_positions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar NOT NULL,
  created_at timestamp DEFAULT now()
);

CREATE TABLE public.job_levels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name varchar NOT NULL,
  created_at timestamp DEFAULT now()
);

CREATE TABLE public.employee_private ( 
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  organization_id uuid REFERENCES public.organizations(id),
  job_position_id uuid REFERENCES public.job_positions(id),
  job_level_id uuid REFERENCES public.job_levels(id),
  employment_status varchar,
  join_date date,
  end_date date,
  approval_line_auth_id uuid REFERENCES auth.users(id),
  manager_line_auth_id uuid REFERENCES auth.users(id),
  created_at timestamp DEFAULT now()
);

ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_public ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_public_pending ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_private ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_levels ENABLE ROW LEVEL SECURITY;

DROP FUNCTION IF EXISTS public.is_hr_user();
--TODO: KONTOLL ganti semua pake function ini buat ngecek role hr

CREATE OR REPLACE FUNCTION public.is_hr_user()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT CASE WHEN EXISTS (
    SELECT 1
    FROM public.users_private up
    WHERE up.auth_id = (SELECT auth.uid())
      AND up.role = 'hr'
  ) THEN TRUE ELSE FALSE END;
$$;

--SELECT schedules
-- HR can sellect all
-- Employee can select only their own schedule based on employee_schedules table
CREATE POLICY select_schedules ON public.schedules
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
  public.is_hr_user()
  OR EXISTS (
    SELECT 1
    FROM public.employee_schedules es
    WHERE es.schedule_id = public.schedules.id
      AND es.auth_id = (select auth.uid())
  )
);
--INSERT schedules
-- HR can insert new schedule
CREATE POLICY insert_schedules ON public.schedules
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_hr_user()
);
--UPDATE schedules
-- HR can update schedule
CREATE POLICY update_schedules ON public.schedules
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
  public.is_hr_user()
);
--DELETE schedules
-- HR can delete schedule
CREATE POLICY delete_schedules ON public.schedules
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
  public.is_hr_user()
);

-- SELECT schedule_shifts
-- HR can select all schedule_shifts
-- Employee can select only their own schedule_shifts based on employee_schedules table
CREATE POLICY select_schedule_shifts ON public.schedule_shifts
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
  public.is_hr_user()
  OR EXISTS (
    SELECT 1
    FROM public.employee_schedules es
    WHERE es.schedule_id = public.schedule_shifts.schedule_id
      AND es.auth_id = (select auth.uid())
  )
);
-- INSERT schedule_shifts
-- HR can insert new schedule_shifts
CREATE POLICY insert_schedule_shifts ON public.schedule_shifts
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_hr_user()
);
-- UPDATE schedule_shifts
-- HR can update schedule_shifts
CREATE POLICY update_schedule_shifts ON public.schedule_shifts
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
  public.is_hr_user()
);
-- DELETE schedule_shifts
-- HR can delete schedule_shifts
CREATE POLICY delete_schedule_shifts ON public.schedule_shifts
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
  public.is_hr_user()
);

-- SELECT shifts
-- HR can select all shifts
-- Employee can select only their own shifts based on employee_schedules table
CREATE POLICY select_shifts ON public.shifts
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
  public.is_hr_user()
  OR EXISTS (
    SELECT 1
    FROM public.employee_schedules es
    JOIN public.schedule_shifts ss ON es.schedule_id = ss.schedule_id
    WHERE ss.shift_id = public.shifts.id
      AND es.auth_id = (select auth.uid())
  ) OR
  (public.shifts.is_requestable = true AND NOT public.is_hr_user() AND NOT EXISTS (
    SELECT 1
    FROM public.users_private up
    WHERE up.auth_id = (select auth.uid())
      AND up.role = 'parent'
  ))
);
-- INSERT shifts
-- HR can insert new shifts
CREATE POLICY insert_shifts ON public.shifts
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_hr_user()
);
-- UPDATE shifts
-- HR can update shifts
CREATE POLICY update_shifts ON public.shifts
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
  public.is_hr_user()
);
-- DELETE shifts
-- HR can delete shifts
CREATE POLICY delete_shifts ON public.shifts
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
  public.is_hr_user()
);

--SELECT employee_schedules
-- HR can select all employee_schedules
-- Employee can select only their own employee_schedules based on auth_id
CREATE POLICY select_employee_schedules ON public.employee_schedules
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
  public.is_hr_user()
  OR public.employee_schedules.auth_id = (select auth.uid())
);
--INSERT employee_schedules
-- HR can insert new employee_schedules
CREATE POLICY insert_employee_schedules ON public.employee_schedules
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_hr_user()
);
--UPDATE employee_schedules
-- HR can update employee_schedules
CREATE POLICY update_employee_schedules ON public.employee_schedules
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
  public.is_hr_user()
);
--DELETE employee_schedules
--HR can delete employee_schedules
CREATE POLICY delete_employee_schedules ON public.employee_schedules
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
  public.is_hr_user()
);

--SELECT employee_public
-- anyone can select employee_public
CREATE POLICY select_employee_public ON public.employee_public
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
  public.is_hr_user()
  OR public.employee_public.auth_id = (select auth.uid())
);
--INSERT employee_public
-- HR can insert new employee_public
CREATE POLICY insert_employee_public ON public.employee_public
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_hr_user()
);
--UPDATE employee_public
-- HR can update employee_public
CREATE POLICY update_employee_public ON public.employee_public
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
  public.is_hr_user()
);
--DELETE employee_public
--HR can delete employee_public
CREATE POLICY delete_employee_public ON public.employee_public
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
  public.is_hr_user()
);

--SELECT employee_public_pending
--the hr can see all and employee can read their own employee_public_pending data
CREATE POLICY select_employee_public_pending ON public.employee_public_pending
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
  auth_id = (select auth.uid()) OR public.is_hr_user()
);

--INSERT employee_public_pending
-- the employee can insert their own employee_public_pending data
CREATE POLICY insert_employee_public_pending ON public.employee_public_pending
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
  public.employee_public_pending.auth_id = (select auth.uid())
);
--UPDATE employee_public_pending
--the employee can update their own employee_public_pending data
CREATE POLICY update_employee_public_pending ON public.employee_public_pending
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
  public.employee_public_pending.auth_id = (select auth.uid())
);
--DELETE employee_public_pending
--HR can delete employee_public_pending 
CREATE POLICY delete_employee_public_pending ON public.employee_public_pending
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
  public.is_hr_user()
);

--SELECT employee_private
-- HR can select all employee_private
-- The manager can select their own employee_private data based on manager_line_auth_id
--only the employee can read their own employee_private data
CREATE POLICY select_employee_private ON public.employee_private
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
  public.is_hr_user()
  OR public.employee_private.manager_line_auth_id = (select auth.uid())
  OR public.employee_private.auth_id = (select auth.uid())
  OR public.employee_private.approval_line_auth_id = (select auth.uid())
);  

--INSERT employee_private
--HR can insert new employee_private
CREATE POLICY insert_employee_private ON public.employee_private
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_hr_user()
);
--UPDATE employee_private
--HR can update employee_private
CREATE POLICY update_employee_private ON public.employee_private
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
  public.is_hr_user()
);
--DELETE employee_private
--HR can delete employee_private
CREATE POLICY delete_employee_private ON public.employee_private
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
  public.is_hr_user()
);


CREATE POLICY select_organizations ON public.organizations
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
  TRUE
);

CREATE POLICY insert_organizations ON public.organizations
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_hr_user()
);

CREATE POLICY update_organizations ON public.organizations
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
  public.is_hr_user()
);

CREATE POLICY delete_organizations ON public.organizations
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
  public.is_hr_user()
);

CREATE POLICY select_job_positions ON public.job_positions
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
  TRUE
);

CREATE POLICY insert_job_positions ON public.job_positions
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_hr_user()
);

CREATE POLICY update_job_positions ON public.job_positions
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
  public.is_hr_user()
);

CREATE POLICY delete_job_positions ON public.job_positions
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
  public.is_hr_user()
);

CREATE POLICY select_job_levels ON public.job_levels
AS PERMISSIVE
FOR SELECT
TO authenticated
USING (
  TRUE
);

CREATE POLICY insert_job_levels ON public.job_levels
AS PERMISSIVE
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_hr_user()
);

CREATE POLICY update_job_levels ON public.job_levels
AS PERMISSIVE
FOR UPDATE
TO authenticated
USING (
  public.is_hr_user()
);

CREATE POLICY delete_job_levels ON public.job_levels
AS PERMISSIVE
FOR DELETE
TO authenticated
USING (
  public.is_hr_user()
);

