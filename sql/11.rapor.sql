DROP TABLE IF EXISTS public.rapor_details CASCADE;
DROP TABLE IF EXISTS public.mapel CASCADE;
DROP TABLE IF EXISTS public.rapor CASCADE;
DROP TYPE IF EXISTS rapor_status CASCADE;   
DROP FUNCTION IF EXISTS public.notify_rapor_issued() CASCADE;


CREATE TYPE rapor_status AS ENUM ('draft', 'issued');
CREATE TABLE public.rapor(
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamptz DEFAULT now(),
    student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    semester int NOT NULL,
    tahun_ajaran varchar NOT NULL,
    status rapor_status NOT NULL DEFAULT 'draft'
);

-- alter table unique per semester, tahun_ajaran, student_id
ALTER TABLE public.rapor ADD CONSTRAINT unique_rapor_per_semester_tahun_ajaran_student UNIQUE (student_id, semester, tahun_ajaran);

-- RLS for rapor
ALTER TABLE public.rapor ENABLE ROW LEVEL SECURITY;
CREATE POLICY rapor_select ON public.rapor FOR SELECT
    USING (status != 'draft' OR EXISTS (
        SELECT 1 FROM public.students WHERE students.id = rapor.student_id AND students.parent_auth_id = (SELECT auth.uid())
    ) OR (SELECT auth.uid()) IN (SELECT auth_id FROM public.users_private WHERE role != 'parent'));

CREATE POLICY rapor_insert ON public.rapor FOR INSERT
    WITH CHECK ((SELECT auth.uid()) IN (SELECT auth_id FROM public.users_private WHERE role != 'parent'));

CREATE POLICY rapor_update ON public.rapor FOR UPDATE
    USING ((SELECT auth.uid()) IN (SELECT auth_id FROM public.users_private WHERE role != 'parent'))
    WITH CHECK ((SELECT auth.uid()) IN (SELECT auth_id FROM public.users_private WHERE role != 'parent'));

CREATE POLICY rapor_delete ON public.rapor FOR DELETE
    USING ((SELECT auth.uid()) IN (SELECT auth_id FROM public.users_private WHERE role != 'parent'));

-- Trigger: notify parent when rapor is issued
CREATE OR REPLACE FUNCTION public.notify_rapor_issued() 
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NEW.status = 'issued' AND OLD.status = 'draft' THEN
        INSERT INTO public.notifications (auth_id, title, body)
        SELECT parent_auth_id, 'Rapor Issued', 'Rapor for ' || students.name || ' has been issued'
        FROM public.students WHERE id = NEW.student_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER rapor_issued_trigger AFTER UPDATE ON public.rapor
    FOR EACH ROW EXECUTE FUNCTION public.notify_rapor_issued();
    
--add pdf column to rapor table
ALTER TABLE public.rapor ADD COLUMN pdf text;