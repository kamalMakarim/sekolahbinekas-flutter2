DROP POLICY IF EXISTS "Employees can insert own attendance" ON public.employee_attendance;

CREATE POLICY "Employees can insert own attendance" ON public.employee_attendance
  FOR INSERT WITH CHECK (
    auth_id = (select auth.uid())
  );

DROP POLICY IF EXISTS "Employees can insert own attendance" ON public.employee_attendance;

ALTER TABLE public.manual_attendance_details DROP COLUMN attendance_id;
ALTER TABLE public.manual_attendance_details ALTER COLUMN is_verified SET DEFAULT NULL;
  
  -- fungsi untuk mencatat cekin cekout dari selfie ke employee_attendance
CREATE OR REPLACE FUNCTION public.sync_manual_to_master()
RETURNS trigger 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- hanya jalan jika yang diupdate is_verifiednya dari false ke true
  IF NEW.is_verified IS TRUE AND OLD.is_verified IS NOT TRUE THEN
    INSERT INTO public.employee_attendance (auth_id, attendance_date, shift_id)
    VALUES (NEW.auth_id, (NEW.created_at + INTERVAL '7 hours')::date, NEW.shift_id)
    ON CONFLICT (auth_id, attendance_date) DO NOTHING; 

    IF NEW.record_type = 'IN' THEN
      UPDATE public.employee_attendance 
      SET check_in = (NEW.created_at + INTERVAL '7 hours')::time, check_in_method = 'selfie'
      WHERE auth_id = NEW.auth_id AND attendance_date = (NEW.created_at + INTERVAL '7 hours')::date;
    ELSE
      UPDATE public.employee_attendance 
      SET check_out = (NEW.created_at + INTERVAL '7 hours')::time, check_out_method = 'selfie'
      WHERE auth_id = NEW.auth_id AND attendance_date = (NEW.created_at + INTERVAL '7 hours')::date;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;