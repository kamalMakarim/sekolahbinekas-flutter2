ALTER TYPE attendance_method RENAME VALUE 'fingerprint' TO 'card';

DROP TABLE IF EXISTS public.employee_fingerprints CASCADE;
DROP TABLE IF EXISTS public.scanners CASCADE;
DROP TABLE IF EXISTS public.processed_fingerprint CASCADE;


DROP TABLE IF EXISTS public.employee_card CASCADE;
DROP TABLE IF EXISTS public.employee_card_scans CASCADE;

CREATE TABLE public.employee_card{
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    card_number text NOT NULL,
    created_at timestamptz DEFAULT now()
};


CREATE TABLE public.employee_card_scans{
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_card_id uuid NOT NULL REFERENCES public.employee_card(id) ON DELETE CASCADE,
    scanned_at timestamptz DEFAULT now()
};

ALTER TABLE public.employee_card ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_card_scans ENABLE ROW LEVEL SECURITY;

-- Triggers
-- AFTER INSERT employee_card_scans, figure out masukin ke employee_attendance, if masukin ke employee_attendance
-- AFTER INSERT employee_attendance, notifiy ke user 'Good morning!, you have successfully clocked in at 08:00 AM'
-- AFTER UPDATE employee_attendance, if checked_out != old.checked_out, notifiy to user 'See you next time, you have successfully clocked out at 05:00 PM' 

