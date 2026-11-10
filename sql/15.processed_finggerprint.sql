CREATE TABLE public.processed_fingerprint (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),  
    fingerprint_id int NOT NULL,
    scanner_id int NOT NULL,
    is_checking_in BOOLEAN,
    display_name varchar,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT (NOW() AT TIME ZONE 'Asia/Jakarta')
);

-- before insert trigger, the ESP only sends fingerprint_id and scanner_id.
-- We resolve the user from employee_fingerprints and users_public without assuming FK relationships.
CREATE OR REPLACE FUNCTION public.set_processed_fingerprint_values()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_auth_id uuid;
    v_display_name text;
    v_today date;
    v_now_time time;
    v_has_check_in boolean;
BEGIN
    -- Resolve employee from the fingerprint mapping table. Do not assume any FK exists.
    SELECT ef.auth_id, COALESCE(up.display_name, 'Unknown')
      INTO v_auth_id, v_display_name
    FROM public.employee_fingerprints ef
    LEFT JOIN public.users_public up ON up.auth_id = ef.auth_id
    WHERE ef.fingerprint_id = NEW.fingerprint_id
      AND ef.scanner_id = NEW.scanner_id
    LIMIT 1;

    -- If fingerprint mapping is missing, keep the row but mark it as not a valid check action.
    IF v_auth_id IS NULL THEN
        NEW.display_name := COALESCE(NEW.display_name, 'Unknown');
        NEW.is_checking_in := FALSE;
        RETURN NEW;
    END IF;

    NEW.display_name := v_display_name;
    v_today := (now() AT TIME ZONE 'Asia/Jakarta')::date;
    v_now_time := (now() AT TIME ZONE 'Asia/Jakarta')::time;

    SELECT COALESCE(check_in IS NOT NULL, FALSE)
      INTO v_has_check_in
    FROM public.employee_attendance
    WHERE auth_id = v_auth_id
      AND attendance_date = v_today
    LIMIT 1;

    IF v_has_check_in THEN
        NEW.is_checking_in := FALSE;

        INSERT INTO public.employee_attendance (auth_id, attendance_date, check_out, check_out_method)
        VALUES (v_auth_id, v_today, v_now_time, 'fingerprint')
        ON CONFLICT (auth_id, attendance_date)
        DO UPDATE SET
            check_out = EXCLUDED.check_out,
            check_out_method = EXCLUDED.check_out_method;
    ELSE
        NEW.is_checking_in := TRUE;

        INSERT INTO public.employee_attendance (auth_id, attendance_date, check_in, check_in_method)
        VALUES (v_auth_id, v_today, v_now_time, 'fingerprint')
        ON CONFLICT (auth_id, attendance_date)
        DO UPDATE SET
            check_in = EXCLUDED.check_in,
            check_in_method = EXCLUDED.check_in_method;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_processed_fingerprint_values ON public.processed_fingerprint;
CREATE TRIGGER trg_set_processed_fingerprint_values
BEFORE INSERT ON public.processed_fingerprint
FOR EACH ROW
EXECUTE FUNCTION public.set_processed_fingerprint_values();


