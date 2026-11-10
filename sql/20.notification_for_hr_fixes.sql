DROP TRIGGER IF EXISTS trg_notify_manual_attendance ON public.manual_attendance_details;
DROP FUNCTION IF EXISTS public.notify_manual_to_admin();

 CREATE OR REPLACE FUNCTION public.notify_shift_change_request()
RETURNS trigger 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.notifications (auth_id, title, body)
    SELECT 
        up.auth_id,
        'Perlu Verifikasi Perubahan Shift',
        'User ' || (SELECT COALESCE(display_name, 'Unknown') FROM public.users_public WHERE auth_id = NEW.auth_id) || ' mengajukan perubahan shift.'
    FROM public.users_private up
    WHERE up.role = 'hr'
    OR up.auth_id = (SELECT ep.approval_line_auth_id FROM public.employee_private ep WHERE ep.auth_id = NEW.auth_id);

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_manual_attendance
AFTER INSERT ON public.manual_attendance_details
FOR EACH ROW
EXECUTE FUNCTION public.notify_shift_change_request();
    
    