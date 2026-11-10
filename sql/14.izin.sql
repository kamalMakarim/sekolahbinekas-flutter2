ALTER TABLE public.employee_attendance ADD COLUMN shift_id uuid REFERENCES public.shifts(id) ON DELETE SET NULL;

CREATE OR REPLACE FUNCTION public.set_employee_attendance_shift_id()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.shift_id IS NULL THEN
    SELECT ss.shift_id
      INTO NEW.shift_id
    FROM public.employee_schedules es
    JOIN public.schedule_shifts ss
      ON ss.schedule_id = es.schedule_id
     AND ss.tanggal = NEW.attendance_date
    WHERE es.auth_id = NEW.auth_id
    ORDER BY ss.created_at DESC
    LIMIT 1;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS before_insert_employee_attendance_set_shift_id ON public.employee_attendance;

CREATE TRIGGER before_insert_employee_attendance_set_shift_id
BEFORE INSERT ON public.employee_attendance
FOR EACH ROW
WHEN (NEW.shift_id IS NULL)
EXECUTE FUNCTION public.set_employee_attendance_shift_id();

ALTER TABLE public.shifts ADD COLUMN is_requestable boolean DEFAULT false;
ALTER TABLE public.manual_attendance_details ADD COLUMN shift_id uuid REFERENCES public.shifts(id) ON DELETE SET NULL;

ALTER TABLE public.employee_public_pending
ADD COLUMN IF NOT EXISTS is_approved boolean DEFAULT false;

CREATE OR REPLACE FUNCTION public.validate_employee_public_pending_approval()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.is_approved IS TRUE THEN
    IF NOT EXISTS (
      SELECT 1
      FROM public.users_private up
      WHERE up.auth_id = (SELECT auth.uid())
        AND up.role = 'hr'
    ) THEN
      RAISE EXCEPTION 'Only HR can approve employee public pending records.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.promote_employee_public_pending()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.is_approved IS TRUE THEN
    INSERT INTO public.employee_public (
      auth_id,
      first_name,
      last_name,
      place_of_birth,
      date_of_birth,
      gender,
      martial_status,
      blood_type,
      religion,
      nik
    ) VALUES (
      NEW.auth_id,
      NEW.first_name,
      NEW.last_name,
      NEW.place_of_birth,
      NEW.date_of_birth,
      NEW.gender,
      NEW.martial_status,
      NEW.blood_type,
      NEW.religion,
      NEW.nik
    );

    DELETE FROM public.employee_public_pending
    WHERE id = NEW.id;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS before_validate_employee_public_pending_approval ON public.employee_public_pending;
CREATE TRIGGER before_validate_employee_public_pending_approval
BEFORE INSERT OR UPDATE ON public.employee_public_pending
FOR EACH ROW
EXECUTE FUNCTION public.validate_employee_public_pending_approval();

DROP TRIGGER IF EXISTS after_promote_employee_public_pending ON public.employee_public_pending;
CREATE TRIGGER after_promote_employee_public_pending
AFTER INSERT OR UPDATE OF is_approved ON public.employee_public_pending
FOR EACH ROW
WHEN (NEW.is_approved IS TRUE)
EXECUTE FUNCTION public.promote_employee_public_pending();

DROP POLICY IF EXISTS "User can view own private data" ON public.users_private;
DROP POLICY IF EXISTS "HR can update private data" ON public.users_private;

CREATE POLICY "User can view own private data" ON public.users_private
  FOR SELECT USING (
    (SELECT auth.uid()) = auth_id
    OR public.is_hr_user()
  );

  CREATE POLICY "HR can update private data" ON public.users_private
  FOR UPDATE USING (
    public.is_hr_user()
  );