ALTER TABLE public.shifts
  ADD COLUMN IF NOT EXISTS require_hr_approval boolean DEFAULT false;

ALTER TABLE public.employee_attendance
  ADD COLUMN IF NOT EXISTS shift_id uuid REFERENCES public.shifts(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS public.change_shift_requests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    attendance_date date NOT NULL,
    shift_id uuid NOT NULL REFERENCES public.shifts(id) ON DELETE CASCADE,
    reason text NOT NULL,
    file_url text NOT NULL,
    is_approved_by_approval_line boolean DEFAULT NULL,
    is_approved_by_hr boolean DEFAULT NULL,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE public.change_shift_requests ADD COLUMN IF NOT EXISTS check_in time;
ALTER TABLE public.change_shift_requests ADD COLUMN IF NOT EXISTS check_out time;

ALTER TABLE public.change_shift_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Employees can insert own change shift requests" ON public.change_shift_requests;
CREATE POLICY "Employees can insert own change shift requests"
ON public.change_shift_requests
FOR INSERT
TO authenticated
WITH CHECK (
  auth_id = (SELECT auth.uid())
);

DROP POLICY IF EXISTS "Employees, managers, and HR can view change shift requests" ON public.change_shift_requests;
CREATE POLICY "Employees, managers, and HR can view change shift requests"
ON public.change_shift_requests
FOR SELECT
TO authenticated
USING (
  auth_id = (SELECT auth.uid())
  OR public.is_hr_user()
  OR EXISTS (
    SELECT 1
    FROM public.employee_private ep
    WHERE ep.auth_id = public.change_shift_requests.auth_id
      AND (
        ep.manager_line_auth_id = (SELECT auth.uid())
        OR ep.approval_line_auth_id = (SELECT auth.uid())
      )
  )
);

DROP POLICY IF EXISTS "Managers and HR can update change shift requests" ON public.change_shift_requests;
CREATE POLICY "Managers and HR can update change shift requests"
ON public.change_shift_requests
FOR UPDATE
TO authenticated
USING (
  public.is_hr_user()
  OR EXISTS (
    SELECT 1
    FROM public.employee_private ep
    WHERE ep.auth_id = public.change_shift_requests.auth_id
      AND (
        ep.manager_line_auth_id = (SELECT auth.uid())
        OR ep.approval_line_auth_id = (SELECT auth.uid())
      )
  )
)
WITH CHECK (
  public.is_hr_user()
  OR EXISTS (
    SELECT 1
    FROM public.employee_private ep
    WHERE ep.auth_id = public.change_shift_requests.auth_id
      AND (
        ep.manager_line_auth_id = (SELECT auth.uid())
        OR ep.approval_line_auth_id = (SELECT auth.uid())
      )
  )
);

CREATE OR REPLACE FUNCTION public.validate_change_shift_request()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.is_approved_by_approval_line IS NOT NULL OR NEW.is_approved_by_hr IS NOT NULL THEN
      RAISE EXCEPTION 'Approval flags must be NULL on insert';
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    IF NEW.is_approved_by_approval_line IS TRUE AND NEW.is_approved_by_hr IS NOT NULL THEN
      -- HR approval is allowed only if the request is approved by the approval line first.
      RETURN NEW;
    END IF;

    IF NEW.is_approved_by_approval_line IS FALSE AND NEW.is_approved_by_hr IS NOT NULL THEN
      RAISE EXCEPTION 'HR approval cannot be set if approval line rejected the request';
    END IF;

    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_change_shift_request_insert_update ON public.change_shift_requests;
CREATE TRIGGER trg_validate_change_shift_request_insert_update
BEFORE INSERT OR UPDATE ON public.change_shift_requests
FOR EACH ROW
EXECUTE FUNCTION public.validate_change_shift_request();

CREATE OR REPLACE FUNCTION public.apply_change_shift_request_approval()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_require_hr_approval boolean;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.is_approved_by_approval_line IS TRUE THEN
    SELECT require_hr_approval
    INTO v_require_hr_approval
    FROM public.shifts
    WHERE id = NEW.shift_id;

    IF v_require_hr_approval IS TRUE THEN
      IF NEW.is_approved_by_hr IS TRUE THEN
        INSERT INTO public.employee_attendance (auth_id, attendance_date, shift_id, check_in, check_out)
        VALUES (NEW.auth_id, NEW.attendance_date, NEW.shift_id, NEW.check_in, NEW.check_out)
        ON CONFLICT (auth_id, attendance_date)
        DO UPDATE SET shift_id = EXCLUDED.shift_id;
      END IF;
    ELSE
      INSERT INTO public.employee_attendance (auth_id, attendance_date, shift_id, check_in, check_out)
      VALUES (NEW.auth_id, NEW.attendance_date, NEW.shift_id, NEW.check_in, NEW.check_out)
      ON CONFLICT (auth_id, attendance_date)
      DO UPDATE SET shift_id = EXCLUDED.shift_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_apply_change_shift_request_approval ON public.change_shift_requests;
CREATE TRIGGER trg_apply_change_shift_request_approval
AFTER UPDATE ON public.change_shift_requests
FOR EACH ROW
WHEN (NEW.is_approved_by_approval_line IS TRUE)
EXECUTE FUNCTION public.apply_change_shift_request_approval();